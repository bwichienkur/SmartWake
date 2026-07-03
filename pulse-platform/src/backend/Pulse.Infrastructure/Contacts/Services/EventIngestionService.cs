using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Application.Contacts.Dtos;
using Pulse.Domain.Common;
using Pulse.Domain.Contacts;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Contacts.Services;

public class EventIngestionService : IEventIngestionService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IOutboxPublisher _outbox;

    public EventIngestionService(PulseDbContext db, ITenantContext tenant, IOutboxPublisher outbox)
    {
        _db = db;
        _tenant = tenant;
        _outbox = outbox;
    }

    public async Task<ContactEventDto> IngestEventAsync(IngestEventRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.EventType))
            throw new AppException(ErrorCodes.Validation, "EventType is required");

        if (!string.IsNullOrEmpty(request.IdempotencyKey))
        {
            var existing = _db.ContactEvents.FirstOrDefault(e =>
                e.WorkspaceId == _tenant.WorkspaceId && e.IdempotencyKey == request.IdempotencyKey);
            if (existing != null)
                return new ContactEventDto(existing.Id, existing.ContactId, existing.EventType, existing.EventName, existing.OccurredAt);
        }

        Contact? contact = null;
        if (request.ContactId.HasValue)
        {
            contact = await _db.Contacts.FindAsync([request.ContactId.Value], ct);
        }
        else if (!string.IsNullOrWhiteSpace(request.Email))
        {
            var email = request.Email.ToLowerInvariant().Trim();
            contact = _db.Contacts.FirstOrDefault(c =>
                c.WorkspaceId == _tenant.WorkspaceId && c.Email == email && !c.IsDeleted);

            if (contact == null)
            {
                contact = Contact.Create(_tenant.WorkspaceId, email);
                _db.Contacts.Add(contact);
            }
        }

        if (contact == null)
            throw new AppException(ErrorCodes.Validation, "ContactId or Email is required");

        if (contact.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.TenantMismatch, "Contact belongs to different workspace", 403);

        var occurredAt = request.OccurredAt ?? DateTimeOffset.UtcNow;
        var evt = new ContactEvent
        {
            WorkspaceId = _tenant.WorkspaceId,
            ContactId = contact.Id,
            EventType = request.EventType,
            EventName = request.EventName,
            Source = request.Source,
            CampaignId = request.CampaignId?.ToString(),
            Revenue = request.Revenue,
            PropertiesJson = request.Properties != null ? System.Text.Json.JsonSerializer.Serialize(request.Properties) : null,
            OccurredAt = occurredAt,
            IdempotencyKey = request.IdempotencyKey
        };

        _db.ContactEvents.Add(evt);
        contact.RecordEngagement(request.EventType, occurredAt);

        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.ContactEventTracked, new
        {
            evt.Id,
            ContactId = contact.Id,
            ContactEmail = contact.Email,
            evt.EventType,
            evt.EventName,
            CampaignId = request.CampaignId,
            evt.Revenue,
            evt.OccurredAt,
            evt.PropertiesJson
        }, request.IdempotencyKey, ct);

        await _db.SaveChangesAsync(ct);

        return new ContactEventDto(evt.Id, evt.ContactId, evt.EventType, evt.EventName, evt.OccurredAt);
    }
}
