namespace Pulse.Domain.Events;

public class OutboxMessage : Entity
{
    public Guid WorkspaceId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string PayloadJson { get; set; } = string.Empty;
    public string? IdempotencyKey { get; set; }
    public DateTimeOffset? PublishedAt { get; set; }
    public int PublishAttempts { get; set; }
    public string? LastError { get; set; }
}

public class InboxMessage : Entity
{
    public Guid WorkspaceId { get; set; }
    public string MessageId { get; set; } = string.Empty;
    public string ConsumerGroup { get; set; } = string.Empty;
    public DateTimeOffset ProcessedAt { get; set; } = DateTimeOffset.UtcNow;
}

public class AnalyticsEvent
{
    public Guid EventId { get; set; } = Guid.NewGuid();
    public Guid WorkspaceId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public Guid? ContactId { get; set; }
    public Guid? CampaignId { get; set; }
    public Guid? AutomationId { get; set; }
    public string? Email { get; set; }
    public string? Domain { get; set; }
    public string? Isp { get; set; }
    public string? Device { get; set; }
    public string? Client { get; set; }
    public string? Country { get; set; }
    public string? Region { get; set; }
    public string? UtmSource { get; set; }
    public string? UtmMedium { get; set; }
    public string? UtmCampaign { get; set; }
    public decimal? Revenue { get; set; }
    public string? PropertiesJson { get; set; }
    public DateTimeOffset OccurredAt { get; set; } = DateTimeOffset.UtcNow;
}
