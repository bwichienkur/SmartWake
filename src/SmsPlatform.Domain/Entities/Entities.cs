namespace SmsPlatform.Domain.Entities;

public abstract class Entity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}

public class Organization : Entity
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public int DailyMessageLimit { get; set; } = 10_000;
    public int RateLimitPerMinute { get; set; } = 100;

    public ICollection<ApiKey> ApiKeys { get; set; } = [];
    public ICollection<Message> Messages { get; set; } = [];
    public ICollection<Contact> Contacts { get; set; } = [];
    public ICollection<Campaign> Campaigns { get; set; } = [];
}

public class ApiKey : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string KeyHash { get; set; } = string.Empty;
    public string KeyPrefix { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTimeOffset? ExpiresAt { get; set; }
    public string[] Scopes { get; set; } = ["messages:send", "messages:read"];
}

public class Contact : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Timezone { get; set; }
    public string ConsentStatus { get; set; } = "Unknown";
    public DateTimeOffset? ConsentRecordedAt { get; set; }
    public string? Tags { get; set; }
}

public class Campaign : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? TenDlcBrandId { get; set; }
    public string? TenDlcCampaignId { get; set; }
    public string UseCase { get; set; } = "transactional";
    public bool IsRegistered { get; set; }
    public int DailyLimit { get; set; } = 1000;
}

public class Message : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public Guid? CampaignId { get; set; }
    public Campaign? Campaign { get; set; }

    public string Direction { get; set; } = "Outbound";
    public string Status { get; set; } = "Queued";
    public string Intent { get; set; } = "Transactional";
    public string Priority { get; set; } = "Normal";

    public string FromNumber { get; set; } = string.Empty;
    public string ToNumber { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? OptimizedBody { get; set; }

    public string? ProviderName { get; set; }
    public string? ProviderMessageId { get; set; }
    public int RetryCount { get; set; }
    public string? FailureReason { get; set; }

    public string? ComplianceDecision { get; set; }
    public string? ComplianceReason { get; set; }
    public DateTimeOffset? ScheduledFor { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public DateTimeOffset? DeliveredAt { get; set; }

    public decimal? EstimatedCost { get; set; }
    public string? CorrelationId { get; set; }
    public string? IdempotencyKey { get; set; }

    public AiInsight? AiInsight { get; set; }
    public ICollection<MessageEvent> Events { get; set; } = [];
}

public class AiInsight : Entity
{
    public Guid MessageId { get; set; }
    public Message Message { get; set; } = null!;

    public string Sentiment { get; set; } = "Unknown";
    public double SentimentScore { get; set; }
    public double ComplianceRiskScore { get; set; }
    public string? SuggestedPriority { get; set; }
    public string? ContentSuggestions { get; set; }
    public string? DetectedIntent { get; set; }
    public bool RequiresHumanReview { get; set; }
}

public class MessageEvent : Entity
{
    public Guid MessageId { get; set; }
    public Message Message { get; set; } = null!;
    public string EventType { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string? ProviderName { get; set; }
}

public class OptOutRecord : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Source { get; set; } = "keyword";
    public string? Keyword { get; set; }
}

public class WebhookSubscription : Entity
{
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public string Url { get; set; } = string.Empty;
    public string[] Events { get; set; } = [];
    public string Secret { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}

public class ProviderHealth : Entity
{
    public string ProviderName { get; set; } = string.Empty;
    public bool IsHealthy { get; set; } = true;
    public double SuccessRate { get; set; } = 1.0;
    public int ConsecutiveFailures { get; set; }
    public DateTimeOffset LastCheckedAt { get; set; } = DateTimeOffset.UtcNow;
}
