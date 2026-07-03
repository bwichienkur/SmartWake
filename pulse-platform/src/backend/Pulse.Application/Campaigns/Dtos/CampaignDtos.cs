namespace Pulse.Application.Campaigns.Dtos;

public record CampaignDto(
    Guid Id,
    Guid BrandId,
    string Name,
    string? Subject,
    string? PreviewText,
    string Status,
    string Type,
    DateTimeOffset? ScheduledAt,
    DateTimeOffset? SentAt,
    long TotalRecipients,
    long TotalSent,
    long TotalDelivered,
    long TotalOpened,
    long TotalClicked,
    long TotalBounced,
    decimal TotalRevenue,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateCampaignRequest(
    Guid BrandId,
    string Name,
    string? Subject = null,
    string? PreviewText = null,
    string? HtmlContent = null,
    string? MjmlContent = null);

public record UpdateCampaignRequest(
    string? Name = null,
    string? Subject = null,
    string? PreviewText = null,
    string? HtmlContent = null,
    string? MjmlContent = null,
    string? FromEmail = null,
    string? FromName = null,
    Guid? SegmentId = null,
    Guid? ListId = null);

public record CampaignListQuery(
    string? Status = null,
    string? Search = null,
    string? After = null,
    int Limit = 50);
