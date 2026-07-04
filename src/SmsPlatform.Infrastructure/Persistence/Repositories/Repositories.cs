using Microsoft.EntityFrameworkCore;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Infrastructure.Persistence.Repositories;

public class MessageRepository : IMessageRepository
{
    private readonly SmsDbContext _db;

    public MessageRepository(SmsDbContext db) => _db = db;

    public Task<Message?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Messages.Include(m => m.AiInsight).FirstOrDefaultAsync(m => m.Id == id, cancellationToken);

    public Task<Message?> GetByIdempotencyKeyAsync(Guid organizationId, string idempotencyKey, CancellationToken cancellationToken = default) =>
        _db.Messages.Include(m => m.AiInsight)
            .FirstOrDefaultAsync(m => m.OrganizationId == organizationId && m.IdempotencyKey == idempotencyKey, cancellationToken);

    public Task<Message?> GetByProviderMessageIdAsync(string providerMessageId, CancellationToken cancellationToken = default) =>
        _db.Messages.FirstOrDefaultAsync(m => m.ProviderMessageId == providerMessageId, cancellationToken);

    public async Task AddAsync(Message message, CancellationToken cancellationToken = default) =>
        await _db.Messages.AddAsync(message, cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _db.SaveChangesAsync(cancellationToken);

    public async Task<(IReadOnlyList<Message> Items, int Total)> ListAsync(
        Guid organizationId, int page, int pageSize, string? direction, CancellationToken cancellationToken = default)
    {
        var query = _db.Messages.Include(m => m.AiInsight).Where(m => m.OrganizationId == organizationId);
        if (!string.IsNullOrWhiteSpace(direction))
        {
            query = query.Where(m => m.Direction == direction);
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderByDescending(m => m.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return (items, total);
    }

    public async Task<DashboardStats> GetStatsAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        var messages = _db.Messages.Where(m => m.OrganizationId == organizationId);
        return new DashboardStats(
            await messages.CountAsync(cancellationToken),
            await messages.CountAsync(m => m.Direction == "Outbound", cancellationToken),
            await messages.CountAsync(m => m.Direction == "Inbound", cancellationToken),
            await messages.CountAsync(m => m.Status == "Blocked", cancellationToken),
            await messages.CountAsync(m => m.Status == "Failed", cancellationToken),
            await _db.Contacts.CountAsync(c => c.OrganizationId == organizationId, cancellationToken),
            await messages.CountAsync(m => m.Status == "Delivered" || m.Status == "Sent", cancellationToken),
            await _db.AiInsights.Where(i => i.Message.OrganizationId == organizationId)
                .Select(i => (double?)i.ComplianceRiskScore).AverageAsync(cancellationToken) ?? 0);
    }
}

public class OrganizationRepository : IOrganizationRepository
{
    private readonly SmsDbContext _db;
    public OrganizationRepository(SmsDbContext db) => _db = db;
    public Task<Organization?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        _db.Organizations.FindAsync([id], cancellationToken).AsTask();
}

public class ContactRepository : IContactRepository
{
    private readonly SmsDbContext _db;
    public ContactRepository(SmsDbContext db) => _db = db;

    public async Task AddAsync(Contact contact, CancellationToken cancellationToken = default) =>
        await _db.Contacts.AddAsync(contact, cancellationToken);

    public Task<IReadOnlyList<Contact>> ListAsync(Guid organizationId, CancellationToken cancellationToken = default) =>
        _db.Contacts.Where(c => c.OrganizationId == organizationId).OrderBy(c => c.Name)
            .ToListAsync(cancellationToken).ContinueWith(t => (IReadOnlyList<Contact>)t.Result, cancellationToken);

    public Task<Contact?> GetByIdAsync(Guid organizationId, Guid contactId, CancellationToken cancellationToken = default) =>
        _db.Contacts.FirstOrDefaultAsync(c => c.OrganizationId == organizationId && c.Id == contactId, cancellationToken);

    public Task DeleteAsync(Contact contact, CancellationToken cancellationToken = default)
    {
        _db.Contacts.Remove(contact);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _db.SaveChangesAsync(cancellationToken);
}

public class OptOutRepository : IOptOutRepository
{
    private readonly SmsDbContext _db;
    public OptOutRepository(SmsDbContext db) => _db = db;

    public Task<bool> ExistsAsync(Guid organizationId, string phoneNumber, CancellationToken cancellationToken = default) =>
        _db.OptOutRecords.AnyAsync(o => o.OrganizationId == organizationId && o.PhoneNumber == phoneNumber, cancellationToken);

    public async Task AddAsync(OptOutRecord record, CancellationToken cancellationToken = default) =>
        await _db.OptOutRecords.AddAsync(record, cancellationToken);

    public Task<int> CountAsync(Guid organizationId, CancellationToken cancellationToken = default) =>
        _db.OptOutRecords.CountAsync(o => o.OrganizationId == organizationId, cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _db.SaveChangesAsync(cancellationToken);
}

public class ComplianceStatsRepository : IComplianceStatsRepository
{
    private readonly SmsDbContext _db;
    public ComplianceStatsRepository(SmsDbContext db) => _db = db;

    public Task<int> CountBlockedAsync(Guid organizationId, CancellationToken cancellationToken = default) =>
        _db.Messages.CountAsync(m => m.OrganizationId == organizationId && m.Status == "Blocked", cancellationToken);

    public Task<int> CountScheduledAsync(Guid organizationId, CancellationToken cancellationToken = default) =>
        _db.Messages.CountAsync(m => m.OrganizationId == organizationId && m.Status == "Scheduled", cancellationToken);

    public Task<int> CountHighRiskAsync(Guid organizationId, CancellationToken cancellationToken = default) =>
        _db.AiInsights.CountAsync(i => i.Message.OrganizationId == organizationId && i.ComplianceRiskScore >= 0.7, cancellationToken);

    public async Task<IReadOnlyList<string>> TopBlockReasonsAsync(Guid organizationId, int take, CancellationToken cancellationToken = default)
    {
        return await _db.Messages
            .Where(m => m.OrganizationId == organizationId && m.Status == "Blocked" && m.ComplianceReason != null)
            .GroupBy(m => m.ComplianceReason!)
            .OrderByDescending(g => g.Count())
            .Take(take)
            .Select(g => g.Key)
            .ToListAsync(cancellationToken);
    }
}

public class AuditService : IAuditService
{
    private readonly SmsDbContext _db;
    public AuditService(SmsDbContext db) => _db = db;

    public async Task RecordEventAsync(Guid messageId, string eventType, string? details = null, string? providerName = null, CancellationToken cancellationToken = default)
    {
        await _db.MessageEvents.AddAsync(new MessageEvent
        {
            MessageId = messageId,
            EventType = eventType,
            Details = details,
            ProviderName = providerName
        }, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);
    }
}
