using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Domain.Common;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Application.Services;

public class ContactService : IContactService
{
    private readonly IContactRepository _contacts;

    public ContactService(IContactRepository contacts)
    {
        _contacts = contacts;
    }

    public async Task<ContactDto> CreateAsync(Guid organizationId, CreateContactRequest request, CancellationToken cancellationToken = default)
    {
        var contact = new Contact
        {
            OrganizationId = organizationId,
            Name = request.Name.Trim(),
            PhoneNumber = PhoneNumberHelper.Normalize(request.PhoneNumber),
            Email = request.Email,
            Timezone = request.Timezone,
            ConsentStatus = request.ConsentStatus,
            ConsentRecordedAt = request.ConsentStatus == "OptedIn" ? DateTimeOffset.UtcNow : null
        };

        await _contacts.AddAsync(contact, cancellationToken);
        await _contacts.SaveChangesAsync(cancellationToken);
        return Map(contact);
    }

    public async Task<IReadOnlyList<ContactDto>> ListAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        var contacts = await _contacts.ListAsync(organizationId, cancellationToken);
        return contacts.Select(Map).ToList();
    }

    public async Task DeleteAsync(Guid organizationId, Guid contactId, CancellationToken cancellationToken = default)
    {
        var contact = await _contacts.GetByIdAsync(organizationId, contactId, cancellationToken)
            ?? throw new KeyNotFoundException("Contact not found");
        await _contacts.DeleteAsync(contact, cancellationToken);
        await _contacts.SaveChangesAsync(cancellationToken);
    }

    private static ContactDto Map(Contact contact) =>
        new(contact.Id, contact.Name, contact.PhoneNumber, contact.Email, contact.ConsentStatus, contact.CreatedAt);
}

public class ComplianceReportService : IComplianceReportService
{
    private readonly IOptOutRepository _optOuts;
    private readonly IComplianceStatsRepository _stats;

    public ComplianceReportService(IOptOutRepository optOuts, IComplianceStatsRepository stats)
    {
        _optOuts = optOuts;
        _stats = stats;
    }

    public async Task<ComplianceReportDto> GetReportAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        var optOutCount = await _optOuts.CountAsync(organizationId, cancellationToken);
        var blocked = await _stats.CountBlockedAsync(organizationId, cancellationToken);
        var scheduled = await _stats.CountScheduledAsync(organizationId, cancellationToken);
        var highRisk = await _stats.CountHighRiskAsync(organizationId, cancellationToken);
        var reasons = await _stats.TopBlockReasonsAsync(organizationId, 5, cancellationToken);

        return new ComplianceReportDto(optOutCount, blocked, scheduled, highRisk, reasons);
    }
}
