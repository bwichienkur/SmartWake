using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Pulse.Domain.Events;
using Pulse.Infrastructure.Analytics;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Workers;

public class OutboxRelayWorker : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<OutboxRelayWorker> _logger;

    public OutboxRelayWorker(IServiceProvider services, ILogger<OutboxRelayWorker> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Outbox relay worker started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessBatchAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Outbox relay batch failed");
            }

            await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);
        }
    }

    private async Task ProcessBatchAsync(CancellationToken ct)
    {
        using var scope = _services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PulseDbContext>();
        var analytics = scope.ServiceProvider.GetRequiredService<IAnalyticsStore>();

        var messages = await db.OutboxMessages
            .Where(m => m.PublishedAt == null && m.PublishAttempts < 5)
            .OrderBy(m => m.CreatedAt)
            .Take(100)
            .ToListAsync(ct);

        foreach (var message in messages)
        {
            try
            {
                // Phase 1: direct analytics ingestion (Kafka in Phase 2)
                var payload = JsonDocument.Parse(message.PayloadJson);
                var contactId = payload.RootElement.TryGetProperty("ContactId", out var cid) && cid.TryGetGuid(out var g)
                    ? g : (Guid?)null;
                var campaignId = payload.RootElement.TryGetProperty("CampaignId", out var camp) && camp.TryGetGuid(out var cg)
                    ? cg : (Guid?)null;

                await analytics.IngestEventAsync(new AnalyticsEventRecord(
                    message.Id,
                    message.WorkspaceId,
                    message.EventType,
                    contactId,
                    campaignId,
                    null,
                    payload.RootElement.TryGetProperty("Revenue", out var rev) ? rev.GetDecimal() : null,
                    message.PayloadJson,
                    message.CreatedAt), ct);

                message.PublishedAt = DateTimeOffset.UtcNow;
                message.LastError = null;
            }
            catch (Exception ex)
            {
                message.PublishAttempts++;
                message.LastError = ex.Message;
                _logger.LogWarning(ex, "Failed to publish outbox message {MessageId}", message.Id);
            }
        }

        if (messages.Count > 0)
            await db.SaveChangesAsync(ct);
    }
}
