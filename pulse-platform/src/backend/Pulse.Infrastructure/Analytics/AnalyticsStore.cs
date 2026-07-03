using Pulse.Application.Reporting.Dtos;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Analytics;

public interface IAnalyticsStore
{
    Task<IReadOnlyList<DailyMetricDto>> GetDailyMetricsAsync(
        Guid workspaceId, DateTimeOffset from, DateTimeOffset to, CancellationToken ct = default);

    Task<CampaignStats> GetCampaignStatsAsync(
        Guid workspaceId, Guid campaignId, CancellationToken ct = default);

    Task IngestEventAsync(AnalyticsEventRecord record, CancellationToken ct = default);
}

public record CampaignStats(
    long Sent, long Delivered, long Opened, long Clicked,
    long Bounced, long Unsubscribed, decimal Revenue);

public record AnalyticsEventRecord(
    Guid EventId,
    Guid WorkspaceId,
    string EventType,
    Guid? ContactId,
    Guid? CampaignId,
    string? Email,
    decimal? Revenue,
    string? PropertiesJson,
    DateTimeOffset OccurredAt);

/// <summary>
/// PostgreSQL-backed analytics store for Phase 1.
/// Production deployments should use ClickHouse via ClickHouseAnalyticsStore.
/// </summary>
public class PostgresAnalyticsStore : IAnalyticsStore
{
    private readonly PulseDbContext _db;

    public PostgresAnalyticsStore(PulseDbContext db) => _db = db;

    public async Task<IReadOnlyList<DailyMetricDto>> GetDailyMetricsAsync(
        Guid workspaceId, DateTimeOffset from, DateTimeOffset to, CancellationToken ct = default)
    {
        var events = _db.ContactEvents
            .Where(e => e.WorkspaceId == workspaceId && e.OccurredAt >= from && e.OccurredAt <= to)
            .ToList();

        var grouped = events
            .GroupBy(e => DateOnly.FromDateTime(e.OccurredAt.UtcDateTime))
            .OrderBy(g => g.Key)
            .Select(g => new DailyMetricDto(
                g.Key,
                g.Count(e => e.EventType.Contains("sent")),
                g.Count(e => e.EventType.Contains("delivered")),
                g.Count(e => e.EventType.Contains("opened")),
                g.Count(e => e.EventType.Contains("clicked")),
                g.Count(e => e.EventType.Contains("bounced")),
                g.Sum(e => e.Revenue ?? 0)))
            .ToList();

        return await Task.FromResult(grouped);
    }

    public async Task<CampaignStats> GetCampaignStatsAsync(
        Guid workspaceId, Guid campaignId, CancellationToken ct = default)
    {
        var campaignIdStr = campaignId.ToString();
        var events = _db.ContactEvents
            .Where(e => e.WorkspaceId == workspaceId && e.CampaignId == campaignIdStr)
            .ToList();

        return await Task.FromResult(new CampaignStats(
            events.Count(e => e.EventType.Contains("sent")),
            events.Count(e => e.EventType.Contains("delivered")),
            events.Count(e => e.EventType.Contains("opened")),
            events.Count(e => e.EventType.Contains("clicked")),
            events.Count(e => e.EventType.Contains("bounced")),
            events.Count(e => e.EventType.Contains("unsubscribed")),
            events.Sum(e => e.Revenue ?? 0)));
    }

    public Task IngestEventAsync(AnalyticsEventRecord record, CancellationToken ct = default)
    {
        // Phase 1: events already stored in contact_events via transactional path
        return Task.CompletedTask;
    }
}
