using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Application.Interfaces;

public interface IMessageRepository
{
    Task<Message?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Message?> GetByIdempotencyKeyAsync(Guid organizationId, string idempotencyKey, CancellationToken cancellationToken = default);
    Task<Message?> GetByProviderMessageIdAsync(string providerMessageId, CancellationToken cancellationToken = default);
    Task AddAsync(Message message, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<Message> Items, int Total)> ListAsync(Guid organizationId, int page, int pageSize, string? direction, CancellationToken cancellationToken = default);
    Task<DashboardStats> GetStatsAsync(Guid organizationId, CancellationToken cancellationToken = default);
}

public record DashboardStats(int Total, int Sent, int Received, int Blocked, int Failed, int Contacts, int Delivered, double AvgComplianceRisk);

public interface IOrganizationRepository
{
    Task<Organization?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}

public interface IContactRepository
{
    Task AddAsync(Contact contact, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Contact>> ListAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task<Contact?> GetByIdAsync(Guid organizationId, Guid contactId, CancellationToken cancellationToken = default);
    Task DeleteAsync(Contact contact, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}

public interface IOptOutRepository
{
    Task<bool> ExistsAsync(Guid organizationId, string phoneNumber, CancellationToken cancellationToken = default);
    Task AddAsync(OptOutRecord record, CancellationToken cancellationToken = default);
    Task<int> CountAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}

public interface IComplianceStatsRepository
{
    Task<int> CountBlockedAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task<int> CountScheduledAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task<int> CountHighRiskAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<string>> TopBlockReasonsAsync(Guid organizationId, int take, CancellationToken cancellationToken = default);
}
