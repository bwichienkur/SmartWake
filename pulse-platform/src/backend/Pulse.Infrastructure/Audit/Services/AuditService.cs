using System.Text.Json;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Domain.Audit;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Audit.Services;

public class AuditService : IAuditService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;

    public AuditService(PulseDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public Task LogAsync(
        string action,
        string entityType,
        Guid? entityId,
        object? oldValues = null,
        object? newValues = null,
        CancellationToken ct = default)
    {
        var log = new AuditLog
        {
            WorkspaceId = _tenant.WorkspaceId,
            UserId = _tenant.UserId,
            ApiKeyId = _tenant.ApiKeyId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            OldValuesJson = oldValues != null ? JsonSerializer.Serialize(oldValues) : null,
            NewValuesJson = newValues != null ? JsonSerializer.Serialize(newValues) : null
        };

        _db.AuditLogs.Add(log);
        return Task.CompletedTask;
    }
}
