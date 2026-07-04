using SmsPlatform.Application.Interfaces;
using SmsPlatform.Domain.Common;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Infrastructure.Compliance;

public class ComplianceEngine : IComplianceEngine
{
    private readonly IOptOutRepository _optOuts;
    private readonly IOrganizationRepository _organizations;

    private static readonly HashSet<string> EssentialIntents =
        ["Otp", "Transactional", "CustomerCare", "Notification"];

    public ComplianceEngine(IOptOutRepository optOuts, IOrganizationRepository organizations)
    {
        _optOuts = optOuts;
        _organizations = organizations;
    }

    public async Task<ComplianceResult> EvaluateOutboundAsync(Message message, CancellationToken cancellationToken = default)
    {
        if (await _optOuts.ExistsAsync(message.OrganizationId, message.ToNumber, cancellationToken))
        {
            return new ComplianceResult("Blocked", "Recipient has opted out (TCPA/CTIA)", null);
        }

        var org = await _organizations.GetByIdAsync(message.OrganizationId, cancellationToken);
        if (org is not null && !org.IsActive)
        {
            return new ComplianceResult("Blocked", "Organization is inactive", null);
        }

        if (ContainsSpamIndicators(message.Body))
        {
            return new ComplianceResult("RequiresReview", "Content flagged for potential spam/compliance risk", null);
        }

        if (IsMarketingIntent(message.Intent) && IsWithinQuietHours(message.ToNumber))
        {
            var scheduledFor = GetNextAllowedSendTime(message.ToNumber);
            return new ComplianceResult("Scheduled", "Marketing message deferred to quiet hours end (TCPA)", scheduledFor);
        }

        if (message.Body.Length > 1600)
        {
            return new ComplianceResult("Blocked", "Message exceeds maximum segment length", null);
        }

        return new ComplianceResult("Allowed", null, null);
    }

    public Task<bool> IsOptedOutAsync(Guid organizationId, string phoneNumber, CancellationToken cancellationToken = default) =>
        _optOuts.ExistsAsync(organizationId, phoneNumber, cancellationToken);

    public async Task RecordOptOutAsync(Guid organizationId, string phoneNumber, string source, string? keyword, CancellationToken cancellationToken = default)
    {
        if (await _optOuts.ExistsAsync(organizationId, phoneNumber, cancellationToken))
        {
            return;
        }

        await _optOuts.AddAsync(new OptOutRecord
        {
            OrganizationId = organizationId,
            PhoneNumber = phoneNumber,
            Source = source,
            Keyword = keyword
        }, cancellationToken);
        await _optOuts.SaveChangesAsync(cancellationToken);
    }

    private static bool IsMarketingIntent(string intent) =>
        intent is "Marketing" or "Events";

    private static bool IsWithinQuietHours(string phoneNumber)
    {
        var timezoneId = PhoneNumberHelper.InferUsTimezone(phoneNumber) ?? "America/New_York";
        var tz = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
        var time = TimeOnly.FromDateTime(local);

        return time >= ComplianceConstants.QuietHoursStart || time < ComplianceConstants.QuietHoursEnd;
    }

    private static DateTimeOffset GetNextAllowedSendTime(string phoneNumber)
    {
        var timezoneId = PhoneNumberHelper.InferUsTimezone(phoneNumber) ?? "America/New_York";
        var tz = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
        var nextLocal = local.TimeOfDay >= ComplianceConstants.QuietHoursStart.ToTimeSpan()
            ? local.Date.AddDays(1).Add(ComplianceConstants.QuietHoursEnd.ToTimeSpan())
            : local.Date.Add(ComplianceConstants.QuietHoursEnd.ToTimeSpan());

        return new DateTimeOffset(nextLocal, tz.GetUtcOffset(nextLocal));
    }

    private static bool ContainsSpamIndicators(string body)
    {
        var lower = body.ToLowerInvariant();
        string[] indicators = ["free money", "click here now", "winner", "act now", "100% free", "no obligation"];
        return indicators.Any(lower.Contains);
    }
}
