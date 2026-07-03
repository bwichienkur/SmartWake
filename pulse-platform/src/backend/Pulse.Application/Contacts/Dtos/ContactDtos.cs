namespace Pulse.Application.Contacts.Dtos;

public record ContactDto(
    Guid Id,
    string Email,
    string? FirstName,
    string? LastName,
    string DisplayName,
    string Status,
    string EmailConsent,
    int EngagementScore,
    DateTimeOffset? LastEngagedAt,
    string? LifecycleStage,
    string? Source,
    Dictionary<string, object?> CustomFields,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateContactRequest(
    string Email,
    string? FirstName = null,
    string? LastName = null,
    string? Phone = null,
    string? ExternalId = null,
    string? Source = null,
    Dictionary<string, object?>? CustomFields = null);

public record UpdateContactRequest(
    string? FirstName = null,
    string? LastName = null,
    string? Phone = null,
    string? LifecycleStage = null,
    Dictionary<string, object?>? CustomFields = null);

public record ContactListQuery(
    string? Search = null,
    string? Status = null,
    string? Tag = null,
    string? After = null,
    int Limit = 50);

public record TrackEventRequest(
    string EventType,
    string? EventName = null,
    string? Source = null,
    decimal? Revenue = null,
    Dictionary<string, object?>? Properties = null,
    DateTimeOffset? OccurredAt = null,
    string? IdempotencyKey = null);

public record IngestEventRequest(
    string? Email = null,
    Guid? ContactId = null,
    string EventType = "",
    string? EventName = null,
    string? Source = null,
    Guid? CampaignId = null,
    decimal? Revenue = null,
    Dictionary<string, object?>? Properties = null,
    DateTimeOffset? OccurredAt = null,
    string? IdempotencyKey = null);

public record ContactEventDto(
    Guid Id,
    Guid ContactId,
    string EventType,
    string? EventName,
    DateTimeOffset OccurredAt);
