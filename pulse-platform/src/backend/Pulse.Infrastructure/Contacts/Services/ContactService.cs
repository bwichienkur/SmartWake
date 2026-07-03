using System.Text.Json;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Application.Contacts.Dtos;
using Pulse.Domain.Common;
using Pulse.Domain.Contacts;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Contacts.Services;

public class ContactService : IContactService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IAuditService _audit;
    private readonly IOutboxPublisher _outbox;

    public ContactService(PulseDbContext db, ITenantContext tenant, IAuditService audit, IOutboxPublisher outbox)
    {
        _db = db;
        _tenant = tenant;
        _audit = audit;
        _outbox = outbox;
    }

    public async Task<ContactDto> CreateAsync(CreateContactRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            throw new AppException(ErrorCodes.Validation, "Email is required");

        var email = request.Email.ToLowerInvariant().Trim();
        var exists = _db.Contacts.Any(c =>
            c.WorkspaceId == _tenant.WorkspaceId && c.Email == email && !c.IsDeleted);
        if (exists)
            throw new AppException(ErrorCodes.Conflict, "Contact with this email already exists", 409);

        var contact = Contact.Create(_tenant.WorkspaceId, email, request.FirstName, request.LastName);
        contact.Phone = request.Phone;
        contact.ExternalId = request.ExternalId;
        contact.Source = request.Source;
        if (request.CustomFields != null)
            contact.CustomFields = request.CustomFields;

        if (_tenant.UserId.HasValue)
            contact.SetCreatedBy(_tenant.UserId.Value);

        _db.Contacts.Add(contact);
        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.ContactCreated, new
        {
            contact.Id,
            contact.Email,
            contact.FirstName,
            contact.LastName
        }, ct: ct);

        await _audit.LogAsync("create", "contact", contact.Id, newValues: contact, ct: ct);
        await _db.SaveChangesAsync(ct);

        return Map(contact);
    }

    public async Task<ContactDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var contact = await _db.Contacts.FindAsync([id], ct);
        if (contact == null || contact.WorkspaceId != _tenant.WorkspaceId || contact.IsDeleted)
            return null;
        return Map(contact);
    }

    public async Task<PagedResult<ContactDto>> ListAsync(ContactListQuery query, CancellationToken ct = default)
    {
        var q = _db.Contacts.Where(c => c.WorkspaceId == _tenant.WorkspaceId && !c.IsDeleted);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.ToLower();
            q = q.Where(c =>
                c.Email.Contains(search) ||
                (c.FirstName != null && c.FirstName.ToLower().Contains(search)) ||
                (c.LastName != null && c.LastName.ToLower().Contains(search)));
        }

        if (!string.IsNullOrWhiteSpace(query.Status) &&
            Enum.TryParse<ContactStatus>(query.Status, true, out var status))
            q = q.Where(c => c.Status == status);

        if (!string.IsNullOrWhiteSpace(query.After) && Guid.TryParse(query.After, out var afterId))
            q = q.Where(c => c.Id.CompareTo(afterId) > 0);

        q = q.OrderBy(c => c.Id);
        var limit = Math.Clamp(query.Limit, 1, 200);
        var items = q.Take(limit + 1).ToList();
        var hasMore = items.Count > limit;
        if (hasMore) items = items.Take(limit).ToList();

        return new PagedResult<ContactDto>
        {
            Items = items.Select(Map).ToList(),
            NextCursor = hasMore ? items[^1].Id.ToString() : null,
            HasMore = hasMore
        };
    }

    public async Task<ContactDto> UpdateAsync(Guid id, UpdateContactRequest request, CancellationToken ct = default)
    {
        var contact = await _db.Contacts.FindAsync([id], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        if (contact.WorkspaceId != _tenant.WorkspaceId || contact.IsDeleted)
            throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        contact.UpdateProfile(request.FirstName, request.LastName, request.Phone);
        if (request.LifecycleStage != null) contact.LifecycleStage = request.LifecycleStage;
        if (request.CustomFields != null) contact.CustomFields = request.CustomFields;
        if (_tenant.UserId.HasValue) contact.SetUpdatedBy(_tenant.UserId.Value);

        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.ContactUpdated, new { contact.Id }, ct: ct);
        await _audit.LogAsync("update", "contact", contact.Id, ct: ct);
        await _db.SaveChangesAsync(ct);

        return Map(contact);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var contact = await _db.Contacts.FindAsync([id], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        if (contact.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        contact.SoftDelete();
        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.ContactDeleted, new { contact.Id }, ct: ct);
        await _audit.LogAsync("delete", "contact", contact.Id, ct: ct);
        await _db.SaveChangesAsync(ct);
    }

    public async Task<ContactEventDto> TrackEventAsync(Guid contactId, TrackEventRequest request, CancellationToken ct = default)
    {
        var contact = await _db.Contacts.FindAsync([contactId], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        if (contact.WorkspaceId != _tenant.WorkspaceId || contact.IsDeleted)
            throw new AppException(ErrorCodes.NotFound, "Contact not found", 404);

        if (!string.IsNullOrEmpty(request.IdempotencyKey))
        {
            var existing = _db.ContactEvents.FirstOrDefault(e =>
                e.WorkspaceId == _tenant.WorkspaceId && e.IdempotencyKey == request.IdempotencyKey);
            if (existing != null)
                return new ContactEventDto(existing.Id, existing.ContactId, existing.EventType, existing.EventName, existing.OccurredAt);
        }

        var occurredAt = request.OccurredAt ?? DateTimeOffset.UtcNow;
        var evt = new ContactEvent
        {
            WorkspaceId = _tenant.WorkspaceId,
            ContactId = contactId,
            EventType = request.EventType,
            EventName = request.EventName,
            Source = request.Source,
            Revenue = request.Revenue,
            PropertiesJson = request.Properties != null ? JsonSerializer.Serialize(request.Properties) : null,
            OccurredAt = occurredAt,
            IdempotencyKey = request.IdempotencyKey
        };

        _db.ContactEvents.Add(evt);
        contact.RecordEngagement(request.EventType, occurredAt);

        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.ContactEventTracked, new
        {
            evt.Id,
            ContactId = contactId,
            evt.EventType,
            evt.EventName,
            evt.Revenue,
            evt.OccurredAt
        }, request.IdempotencyKey, ct);

        await _db.SaveChangesAsync(ct);

        return new ContactEventDto(evt.Id, evt.ContactId, evt.EventType, evt.EventName, evt.OccurredAt);
    }

    private static ContactDto Map(Contact c) => new(
        c.Id, c.Email, c.FirstName, c.LastName, c.DisplayName,
        c.Status.ToString(), c.EmailConsent.ToString(), c.EngagementScore,
        c.LastEngagedAt, c.LifecycleStage, c.Source, c.CustomFields,
        c.CreatedAt, c.UpdatedAt);
}
