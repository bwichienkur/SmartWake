namespace Pulse.Domain.Campaigns;

public enum CampaignStatus
{
    Draft,
    Scheduled,
    Sending,
    Sent,
    Paused,
    Cancelled,
    Archived
}

public enum CampaignType
{
    Regular,
    AbTest,
    Multivariate,
    Transactional
}

public class Campaign : AuditableEntity
{
    public Guid BrandId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Subject { get; set; }
    public string? PreviewText { get; set; }
    public CampaignStatus Status { get; set; } = CampaignStatus.Draft;
    public CampaignType Type { get; set; } = CampaignType.Regular;
    public string? FromEmail { get; set; }
    public string? FromName { get; set; }
    public string? ReplyToEmail { get; set; }
    public Guid? SegmentId { get; set; }
    public Guid? ListId { get; set; }
    public string? HtmlContent { get; set; }
    public string? MjmlContent { get; set; }
    public string? PlainTextContent { get; set; }
    public DateTimeOffset? ScheduledAt { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public int Version { get; set; } = 1;
    public string? UtmSource { get; set; }
    public string? UtmMedium { get; set; }
    public string? UtmCampaign { get; set; }
    public bool RequiresApproval { get; set; }
    public Guid? ApprovedByUserId { get; set; }
    public DateTimeOffset? ApprovedAt { get; set; }

    // Denormalized stats (updated via events)
    public long TotalRecipients { get; set; }
    public long TotalSent { get; set; }
    public long TotalDelivered { get; set; }
    public long TotalOpened { get; set; }
    public long TotalClicked { get; set; }
    public long TotalBounced { get; set; }
    public long TotalUnsubscribed { get; set; }
    public decimal TotalRevenue { get; set; }

    public static Campaign Create(Guid workspaceId, Guid brandId, string name)
    {
        return new Campaign
        {
            WorkspaceId = workspaceId,
            BrandId = brandId,
            Name = name
        };
    }

    public void Schedule(DateTimeOffset scheduledAt)
    {
        ScheduledAt = scheduledAt;
        Status = CampaignStatus.Scheduled;
        Touch();
    }

    public void MarkSending()
    {
        Status = CampaignStatus.Sending;
        Touch();
    }

    public void MarkSent()
    {
        Status = CampaignStatus.Sent;
        SentAt = DateTimeOffset.UtcNow;
        Touch();
    }
}

public class CampaignVersion : TenantEntity
{
    public Guid CampaignId { get; set; }
    public int VersionNumber { get; set; }
    public string? Subject { get; set; }
    public string? HtmlContent { get; set; }
    public string? MjmlContent { get; set; }
    public string? ChangeNotes { get; set; }
    public Guid CreatedByUserId { get; set; }
}

public class CampaignSend : TenantEntity
{
    public Guid CampaignId { get; set; }
    public Guid ContactId { get; set; }
    public string Status { get; set; } = "queued";
    public string? ProviderMessageId { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public DateTimeOffset? DeliveredAt { get; set; }
    public string? BounceType { get; set; }
    public string? BounceReason { get; set; }
}
