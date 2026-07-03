namespace Pulse.Application.Reporting.Dtos;

public record ReportQuery(
    DateTimeOffset? From = null,
    DateTimeOffset? To = null,
    Guid? CampaignId = null,
    Guid? SegmentId = null);

public record ExecutiveDashboardDto(
    DateTimeOffset From,
    DateTimeOffset To,
    long TotalContacts,
    long ContactGrowth,
    long TotalSent,
    long TotalDelivered,
    long TotalOpened,
    long TotalClicked,
    long TotalBounced,
    long TotalUnsubscribed,
    decimal TotalRevenue,
    double DeliveryRate,
    double OpenRate,
    double ClickRate,
    double BounceRate,
    IReadOnlyList<DailyMetricDto> DailyMetrics);

public record DailyMetricDto(
    DateOnly Date,
    long Sent,
    long Delivered,
    long Opened,
    long Clicked,
    long Bounced,
    decimal Revenue);

public record CampaignPerformanceDto(
    Guid CampaignId,
    string CampaignName,
    long TotalSent,
    long TotalDelivered,
    long TotalOpened,
    long TotalClicked,
    long TotalBounced,
    long TotalUnsubscribed,
    decimal TotalRevenue,
    double DeliveryRate,
    double OpenRate,
    double ClickRate,
    double ClickToOpenRate);
