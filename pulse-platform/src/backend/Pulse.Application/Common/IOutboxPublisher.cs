namespace Pulse.Application.Common;

public interface IOutboxPublisher
{
    Task PublishAsync(
        Guid workspaceId,
        string eventType,
        object payload,
        string? idempotencyKey = null,
        CancellationToken ct = default);
}
