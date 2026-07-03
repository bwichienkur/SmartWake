using Pulse.Application.Contacts.Dtos;
using Pulse.Application.Common;

namespace Pulse.Application.Contacts;

public interface IContactService
{
    Task<ContactDto> CreateAsync(CreateContactRequest request, CancellationToken ct = default);
    Task<ContactDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<PagedResult<ContactDto>> ListAsync(ContactListQuery query, CancellationToken ct = default);
    Task<ContactDto> UpdateAsync(Guid id, UpdateContactRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
    Task<ContactEventDto> TrackEventAsync(Guid contactId, TrackEventRequest request, CancellationToken ct = default);
}

public interface ICampaignService
{
    Task<Campaigns.Dtos.CampaignDto> CreateAsync(Campaigns.Dtos.CreateCampaignRequest request, CancellationToken ct = default);
    Task<Campaigns.Dtos.CampaignDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<PagedResult<Campaigns.Dtos.CampaignDto>> ListAsync(Campaigns.Dtos.CampaignListQuery query, CancellationToken ct = default);
    Task<Campaigns.Dtos.CampaignDto> UpdateAsync(Guid id, Campaigns.Dtos.UpdateCampaignRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
}

public interface IEventIngestionService
{
    Task<ContactEventDto> IngestEventAsync(IngestEventRequest request, CancellationToken ct = default);
}

public interface IReportingService
{
    Task<Reporting.Dtos.ExecutiveDashboardDto> GetExecutiveDashboardAsync(Reporting.Dtos.ReportQuery query, CancellationToken ct = default);
    Task<Reporting.Dtos.CampaignPerformanceDto> GetCampaignPerformanceAsync(Guid campaignId, CancellationToken ct = default);
}

public interface IAuthService
{
    Task<Auth.Dtos.AuthResponse> LoginAsync(Auth.Dtos.LoginRequest request, CancellationToken ct = default);
    Task<Auth.Dtos.AuthResponse> RegisterAsync(Auth.Dtos.RegisterRequest request, CancellationToken ct = default);
    Task<Auth.Dtos.UserProfileDto> GetProfileAsync(CancellationToken ct = default);
}

public interface IAuditService
{
    Task LogAsync(string action, string entityType, Guid? entityId, object? oldValues = null, object? newValues = null, CancellationToken ct = default);
}
