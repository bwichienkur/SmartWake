namespace SmsPlatform.Application.DTOs;

public record SendMessageRequest(
    string To,
    string Body,
    string Intent = "Transactional",
    string Priority = "Normal",
    string? From = null,
    Guid? CampaignId = null,
    string? IdempotencyKey = null,
    bool EnableAiOptimization = false);

public record SendMessageResponse(
    Guid MessageId,
    string Status,
    string? ComplianceDecision,
    string? ComplianceReason,
    DateTimeOffset? ScheduledFor,
    AiInsightDto? AiInsight);

public record AiInsightDto(
    string Sentiment,
    double SentimentScore,
    double ComplianceRiskScore,
    string? SuggestedPriority,
    string? ContentSuggestions,
    bool RequiresHumanReview);

public record MessageDto(
    Guid Id,
    string Direction,
    string Status,
    string Intent,
    string Priority,
    string FromNumber,
    string ToNumber,
    string Body,
    string? ProviderName,
    string? ComplianceDecision,
    DateTimeOffset CreatedAt,
    DateTimeOffset? ScheduledFor,
    DateTimeOffset? SentAt,
    AiInsightDto? AiInsight);

public record PaginatedResult<T>(IReadOnlyList<T> Items, int Total, int Page, int PageSize);

public record CreateContactRequest(string Name, string PhoneNumber, string? Email, string? Timezone, string ConsentStatus = "OptedIn");

public record ContactDto(Guid Id, string Name, string PhoneNumber, string? Email, string ConsentStatus, DateTimeOffset CreatedAt);

public record DashboardStatsDto(
    int TotalMessages,
    int Sent,
    int Received,
    int Blocked,
    int Failed,
    int Contacts,
    double DeliveryRate,
    double AvgComplianceRisk);

public record AnalyzeContentRequest(string Body, string Intent = "Transactional");

public record AnalyzeContentResponse(
    double ComplianceRiskScore,
    string RiskLevel,
    IReadOnlyList<string> Issues,
    string? SuggestedBody,
    string? RecommendedIntent);

public record ProviderHealthDto(string ProviderName, bool IsHealthy, double SuccessRate, int ConsecutiveFailures);

public record ComplianceReportDto(
    int OptOutCount,
    int BlockedMessages,
    int ScheduledMessages,
    int HighRiskMessages,
    IReadOnlyList<string> TopBlockReasons);
