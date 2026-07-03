namespace Pulse.Domain.Common;

public interface IDomainEvent
{
    Guid EventId { get; }
    string EventType { get; }
    Guid WorkspaceId { get; }
    DateTimeOffset OccurredAt { get; }
    object Payload { get; }
}

public record DomainEvent(
    Guid EventId,
    string EventType,
    Guid WorkspaceId,
    DateTimeOffset OccurredAt,
    object Payload) : IDomainEvent;

public static class EventTypes
{
    public const string ContactCreated = "contact.created";
    public const string ContactUpdated = "contact.updated";
    public const string ContactDeleted = "contact.deleted";
    public const string ContactEventTracked = "contact.event.tracked";
    public const string CampaignCreated = "campaign.created";
    public const string CampaignUpdated = "campaign.updated";
    public const string CampaignSent = "campaign.sent";
    public const string EmailDelivered = "email.delivered";
    public const string EmailOpened = "email.opened";
    public const string EmailClicked = "email.clicked";
    public const string EmailBounced = "email.bounced";
    public const string EmailComplained = "email.complained";
    public const string EmailUnsubscribed = "email.unsubscribed";
    public const string AutomationEntered = "automation.entered";
    public const string AutomationExited = "automation.exited";
    public const string AuditLogged = "audit.logged";
}
