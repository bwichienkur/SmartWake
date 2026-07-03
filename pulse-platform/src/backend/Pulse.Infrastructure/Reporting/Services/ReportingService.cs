using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Application.Reporting.Dtos;
using Pulse.Infrastructure.Analytics;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Reporting.Services;

public class ReportingService : IReportingService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IAnalyticsStore _analytics;

    public ReportingService(PulseDbContext db, ITenantContext tenant, IAnalyticsStore analytics)
    {
        _db = db;
        _tenant = tenant;
        _analytics = analytics;
    }

    public async Task<ExecutiveDashboardDto> GetExecutiveDashboardAsync(ReportQuery query, CancellationToken ct = default)
    {
        var from = query.From ?? DateTimeOffset.UtcNow.AddDays(-30);
        var to = query.To ?? DateTimeOffset.UtcNow;

        var totalContacts = _db.Contacts.Count(c => c.WorkspaceId == _tenant.WorkspaceId && !c.IsDeleted);
        var newContacts = _db.Contacts.Count(c =>
            c.WorkspaceId == _tenant.WorkspaceId && !c.IsDeleted && c.CreatedAt >= from && c.CreatedAt <= to);

        var metrics = await _analytics.GetDailyMetricsAsync(_tenant.WorkspaceId, from, to, ct);

        var totalSent = metrics.Sum(m => m.Sent);
        var totalDelivered = metrics.Sum(m => m.Delivered);
        var totalOpened = metrics.Sum(m => m.Opened);
        var totalClicked = metrics.Sum(m => m.Clicked);
        var totalBounced = metrics.Sum(m => m.Bounced);
        var totalRevenue = metrics.Sum(m => m.Revenue);

        return new ExecutiveDashboardDto(
            from, to,
            totalContacts, newContacts,
            totalSent, totalDelivered, totalOpened, totalClicked, totalBounced, 0,
            totalRevenue,
            Rate(totalDelivered, totalSent),
            Rate(totalOpened, totalDelivered),
            Rate(totalClicked, totalDelivered),
            Rate(totalBounced, totalSent),
            metrics);
    }

    public async Task<CampaignPerformanceDto> GetCampaignPerformanceAsync(Guid campaignId, CancellationToken ct = default)
    {
        var campaign = await _db.Campaigns.FindAsync([campaignId], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        if (campaign.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        var stats = await _analytics.GetCampaignStatsAsync(_tenant.WorkspaceId, campaignId, ct);

        return new CampaignPerformanceDto(
            campaign.Id, campaign.Name,
            stats.Sent, stats.Delivered, stats.Opened, stats.Clicked,
            stats.Bounced, stats.Unsubscribed, stats.Revenue,
            Rate(stats.Delivered, stats.Sent),
            Rate(stats.Opened, stats.Delivered),
            Rate(stats.Clicked, stats.Delivered),
            Rate(stats.Clicked, stats.Opened));
    }

    private static double Rate(long numerator, long denominator) =>
        denominator == 0 ? 0 : Math.Round((double)numerator / denominator * 100, 2);
}
