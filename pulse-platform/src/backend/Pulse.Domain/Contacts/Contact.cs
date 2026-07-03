namespace Pulse.Domain.Contacts;

public enum ContactStatus
{
    Active,
    Unsubscribed,
    Bounced,
    Complained,
    Suppressed
}

public enum ConsentStatus
{
    Unknown,
    OptIn,
    OptOut,
    DoubleOptIn
}

public class Contact : AuditableEntity
{
    public string Email { get; private set; } = string.Empty;
    public string? Phone { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public ContactStatus Status { get; private set; } = ContactStatus.Active;
    public ConsentStatus EmailConsent { get; set; } = ConsentStatus.Unknown;
    public ConsentStatus SmsConsent { get; set; } = ConsentStatus.Unknown;
    public string? ExternalId { get; set; }
    public string? AnonymousId { get; set; }
    public string? EcommerceCustomerId { get; set; }
    public string? CrmContactId { get; set; }
    public string? LifecycleStage { get; set; }
    public string? Source { get; set; }
    public decimal? LeadScore { get; set; }
    public decimal? Ltv { get; set; }
    public int EngagementScore { get; set; }
    public DateTimeOffset? LastEngagedAt { get; set; }
    public DateTimeOffset? LastEmailSentAt { get; set; }
    public DateTimeOffset? LastEmailOpenedAt { get; set; }
    public DateTimeOffset? LastEmailClickedAt { get; set; }
    public Dictionary<string, object?> CustomFields { get; set; } = new();
    public bool IsDeleted { get; private set; }
    public DateTimeOffset? DeletedAt { get; private set; }

    private Contact() { }

    public static Contact Create(Guid workspaceId, string email, string? firstName = null, string? lastName = null)
    {
        return new Contact
        {
            WorkspaceId = workspaceId,
            Email = email.ToLowerInvariant().Trim(),
            FirstName = firstName,
            LastName = lastName
        };
    }

    public string DisplayName =>
        !string.IsNullOrWhiteSpace($"{FirstName} {LastName}".Trim())
            ? $"{FirstName} {LastName}".Trim()
            : Email;

    public void UpdateProfile(string? firstName, string? lastName, string? phone)
    {
        FirstName = firstName ?? FirstName;
        LastName = lastName ?? LastName;
        Phone = phone ?? Phone;
        Touch();
    }

    public void Suppress(ContactStatus status)
    {
        Status = status;
        Touch();
    }

    public void SoftDelete()
    {
        IsDeleted = true;
        DeletedAt = DateTimeOffset.UtcNow;
        Touch();
    }

    public void RecordEngagement(string engagementType, DateTimeOffset occurredAt)
    {
        LastEngagedAt = occurredAt;
        EngagementScore = Math.Min(EngagementScore + 1, 100);
        if (engagementType == "email.opened") LastEmailOpenedAt = occurredAt;
        if (engagementType == "email.clicked") LastEmailClickedAt = occurredAt;
        Touch();
    }
}

public class ContactTag : TenantEntity
{
    public Guid ContactId { get; set; }
    public string Tag { get; set; } = string.Empty;
}

public class ContactList : AuditableEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int ContactCount { get; set; }
    public bool IsDynamic { get; set; }
    public string? SegmentDefinitionJson { get; set; }
}

public class ContactListMembership : TenantEntity
{
    public Guid ListId { get; set; }
    public Guid ContactId { get; set; }
    public DateTimeOffset AddedAt { get; set; } = DateTimeOffset.UtcNow;
}

public class ContactEvent : TenantEntity
{
    public Guid ContactId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string? EventName { get; set; }
    public string? Source { get; set; }
    public string? CampaignId { get; set; }
    public string? AutomationId { get; set; }
    public decimal? Revenue { get; set; }
    public string? PropertiesJson { get; set; }
    public DateTimeOffset OccurredAt { get; set; } = DateTimeOffset.UtcNow;
    public string? IdempotencyKey { get; set; }

    public static ContactEvent Create(Guid workspaceId, Guid contactId, string eventType) =>
        new() { WorkspaceId = workspaceId, ContactId = contactId, EventType = eventType };
}

public class ConsentRecord : TenantEntity
{
    public Guid ContactId { get; set; }
    public string Channel { get; set; } = "email";
    public ConsentStatus Status { get; set; }
    public string? Source { get; set; }
    public string? IpAddress { get; set; }
    public DateTimeOffset RecordedAt { get; set; } = DateTimeOffset.UtcNow;
}
