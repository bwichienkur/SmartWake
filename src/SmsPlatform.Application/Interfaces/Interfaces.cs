using SmsPlatform.Application.DTOs;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Application.Interfaces;

public interface IComplianceEngine
{
    Task<ComplianceResult> EvaluateOutboundAsync(Message message, CancellationToken cancellationToken = default);
    Task<bool> IsOptedOutAsync(Guid organizationId, string phoneNumber, CancellationToken cancellationToken = default);
    Task RecordOptOutAsync(Guid organizationId, string phoneNumber, string source, string? keyword, CancellationToken cancellationToken = default);
}

public record ComplianceResult(string Decision, string? Reason, DateTimeOffset? ScheduledFor);

public interface IIntelligenceService
{
    Task<AiInsight> AnalyzeOutboundAsync(Message message, CancellationToken cancellationToken = default);
    Task<AiInsight> AnalyzeInboundAsync(Message message, CancellationToken cancellationToken = default);
    Task<AnalyzeContentResponse> AnalyzeContentAsync(AnalyzeContentRequest request, CancellationToken cancellationToken = default);
}

public interface ISmsProvider
{
    string Name { get; }
    Task<ProviderSendResult> SendAsync(ProviderSendRequest request, CancellationToken cancellationToken = default);
    Task<bool> HealthCheckAsync(CancellationToken cancellationToken = default);
}

public record ProviderSendRequest(string From, string To, string Body, string? StatusCallbackUrl);

public interface ISmsProviderRouter
{
    Task<ProviderSendResult> SendWithFailoverAsync(Message message, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ProviderHealthDto>> GetHealthAsync(CancellationToken cancellationToken = default);
}

public interface IMessageService
{
    Task<SendMessageResponse> QueueOutboundAsync(Guid organizationId, SendMessageRequest request, CancellationToken cancellationToken = default);
    Task<Message?> ProcessOutboundAsync(Guid messageId, CancellationToken cancellationToken = default);
    Task<Message> HandleInboundAsync(Guid organizationId, InboundWebhookPayload payload, CancellationToken cancellationToken = default);
    Task UpdateDeliveryStatusAsync(string providerMessageId, string status, CancellationToken cancellationToken = default);
    Task<PaginatedResult<MessageDto>> ListMessagesAsync(Guid organizationId, int page, int pageSize, string? direction, CancellationToken cancellationToken = default);
    Task<DashboardStatsDto> GetStatsAsync(Guid organizationId, CancellationToken cancellationToken = default);
}

public record InboundWebhookPayload(string From, string To, string Body, string ProviderMessageId, string ProviderName);

public interface IContactService
{
    Task<ContactDto> CreateAsync(Guid organizationId, CreateContactRequest request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ContactDto>> ListAsync(Guid organizationId, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid organizationId, Guid contactId, CancellationToken cancellationToken = default);
}

public interface IAuditService
{
    Task RecordEventAsync(Guid messageId, string eventType, string? details = null, string? providerName = null, CancellationToken cancellationToken = default);
}

public interface IApiKeyValidator
{
    Task<Organization?> ValidateAsync(string apiKey, CancellationToken cancellationToken = default);
}

public interface IComplianceReportService
{
    Task<ComplianceReportDto> GetReportAsync(Guid organizationId, CancellationToken cancellationToken = default);
}
