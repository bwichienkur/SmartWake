using System.Text.Json;
using Pulse.Application.Common;
using Pulse.Domain.Events;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Common;

public class OutboxPublisher : IOutboxPublisher
{
    private readonly PulseDbContext _db;

    public OutboxPublisher(PulseDbContext db) => _db = db;

    public Task PublishAsync(
        Guid workspaceId,
        string eventType,
        object payload,
        string? idempotencyKey = null,
        CancellationToken ct = default)
    {
        var message = new OutboxMessage
        {
            WorkspaceId = workspaceId,
            EventType = eventType,
            PayloadJson = JsonSerializer.Serialize(payload),
            IdempotencyKey = idempotencyKey
        };

        _db.OutboxMessages.Add(message);
        return Task.CompletedTask;
    }
}
