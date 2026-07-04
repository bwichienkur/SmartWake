namespace SmsPlatform.Domain.Enums;

public enum MessageDirection
{
    Inbound = 0,
    Outbound = 1
}

public enum MessageStatus
{
    Queued = 0,
    Scheduled = 1,
    Processing = 2,
    Sent = 3,
    Delivered = 4,
    Failed = 5,
    Received = 6,
    Blocked = 7,
    Cancelled = 8
}

public enum MessageIntent
{
    Otp = 0,
    Transactional = 1,
    CustomerCare = 2,
    Notification = 3,
    Marketing = 4,
    Events = 5
}

public enum MessagePriority
{
    Low = 0,
    Normal = 1,
    High = 2,
    Critical = 3
}

public enum ProviderType
{
    Twilio = 0,
    Vonage = 1,
    Plivo = 2,
    Mock = 99
}

public enum ComplianceDecision
{
    Allowed = 0,
    Blocked = 1,
    Scheduled = 2,
    RequiresReview = 3
}

public enum ConsentStatus
{
    Unknown = 0,
    OptedIn = 1,
    OptedOut = 2
}

public enum SentimentLabel
{
    Unknown = 0,
    Positive = 1,
    Neutral = 2,
    Negative = 3,
    Urgent = 4
}

public enum AuditEventType
{
    MessageQueued = 0,
    ComplianceChecked = 1,
    AiAnalyzed = 2,
    ProviderDispatched = 3,
    DeliveryUpdated = 4,
    OptOutRecorded = 5,
    WebhookDelivered = 6,
    FailoverAttempted = 7
}
