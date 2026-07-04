using Microsoft.Extensions.Logging;
using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Domain.Common;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Application.Services;

public class MessageService : IMessageService
{
    private readonly IMessageRepository _messages;
    private readonly IOrganizationRepository _organizations;
    private readonly IComplianceEngine _compliance;
    private readonly IIntelligenceService _intelligence;
    private readonly ISmsProviderRouter _providerRouter;
    private readonly IAuditService _audit;
    private readonly IMessageQueue _queue;
    private readonly ILogger<MessageService> _logger;

    public MessageService(
        IMessageRepository messages,
        IOrganizationRepository organizations,
        IComplianceEngine compliance,
        IIntelligenceService intelligence,
        ISmsProviderRouter providerRouter,
        IAuditService audit,
        IMessageQueue queue,
        ILogger<MessageService> logger)
    {
        _messages = messages;
        _organizations = organizations;
        _compliance = compliance;
        _intelligence = intelligence;
        _providerRouter = providerRouter;
        _audit = audit;
        _queue = queue;
        _logger = logger;
    }

    public async Task<SendMessageResponse> QueueOutboundAsync(Guid organizationId, SendMessageRequest request, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            var existing = await _messages.GetByIdempotencyKeyAsync(organizationId, request.IdempotencyKey, cancellationToken);
            if (existing is not null)
            {
                return MapSendResponse(existing);
            }
        }

        _ = await _organizations.GetByIdAsync(organizationId, cancellationToken)
            ?? throw new InvalidOperationException("Organization not found");

        var message = new Message
        {
            OrganizationId = organizationId,
            CampaignId = request.CampaignId,
            Direction = "Outbound",
            Status = "Queued",
            Intent = request.Intent,
            Priority = request.Priority,
            FromNumber = request.From ?? "+15550000001",
            ToNumber = PhoneNumberHelper.Normalize(request.To),
            Body = request.Body.Trim(),
            IdempotencyKey = request.IdempotencyKey,
            CorrelationId = Guid.NewGuid().ToString("N")
        };

        if (request.EnableAiOptimization)
        {
            var analysis = await _intelligence.AnalyzeOutboundAsync(message, cancellationToken);
            message.AiInsight = analysis;
            if (!string.IsNullOrWhiteSpace(analysis.ContentSuggestions))
            {
                message.OptimizedBody = analysis.ContentSuggestions;
            }
        }

        var compliance = await _compliance.EvaluateOutboundAsync(message, cancellationToken);
        message.ComplianceDecision = compliance.Decision;
        message.ComplianceReason = compliance.Reason;
        message.ScheduledFor = compliance.ScheduledFor;

        message.Status = compliance.Decision switch
        {
            "Blocked" => "Blocked",
            "Scheduled" => "Scheduled",
            _ => "Queued"
        };

        await _messages.AddAsync(message, cancellationToken);
        await _messages.SaveChangesAsync(cancellationToken);
        await _audit.RecordEventAsync(message.Id, "ComplianceChecked", compliance.Reason, cancellationToken: cancellationToken);

        if (message.Status == "Queued")
        {
            await _queue.PublishAsync(new OutboundMessageJob(message.Id), cancellationToken);
            await _audit.RecordEventAsync(message.Id, "MessageQueued", cancellationToken: cancellationToken);
        }

        return MapSendResponse(message);
    }

    public async Task<Message?> ProcessOutboundAsync(Guid messageId, CancellationToken cancellationToken = default)
    {
        var message = await _messages.GetByIdAsync(messageId, cancellationToken);
        if (message is null || message.Direction != "Outbound")
        {
            return null;
        }

        if (message.Status == "Scheduled" && message.ScheduledFor > DateTimeOffset.UtcNow)
        {
            return message;
        }

        if (message.Status is not ("Queued" or "Scheduled"))
        {
            return message;
        }

        message.Status = "Processing";
        await _messages.SaveChangesAsync(cancellationToken);

        try
        {
            var result = await _providerRouter.SendWithFailoverAsync(message, cancellationToken);
            message.ProviderMessageId = result.ProviderMessageId;
            message.ProviderName = result.ProviderName;
            message.EstimatedCost = result.EstimatedCost;
            message.Status = result.Success ? "Sent" : "Failed";
            message.FailureReason = result.ErrorMessage;
            message.SentAt = result.Success ? DateTimeOffset.UtcNow : null;

            await _audit.RecordEventAsync(message.Id, "ProviderDispatched", result.ErrorMessage, result.ProviderName, cancellationToken);
        }
        catch (Exception ex)
        {
            message.Status = "Failed";
            message.FailureReason = ex.Message;
            message.RetryCount++;
            _logger.LogError(ex, "Failed to send message {MessageId}", messageId);
        }

        message.UpdatedAt = DateTimeOffset.UtcNow;
        await _messages.SaveChangesAsync(cancellationToken);
        return message;
    }

    public async Task<Message> HandleInboundAsync(Guid organizationId, InboundWebhookPayload payload, CancellationToken cancellationToken = default)
    {
        var normalizedFrom = PhoneNumberHelper.Normalize(payload.From);
        var body = payload.Body.Trim();

        if (OptOutKeywords.Keywords.Any(k => body.Equals(k, StringComparison.OrdinalIgnoreCase)))
        {
            await _compliance.RecordOptOutAsync(organizationId, normalizedFrom, "keyword", body.ToUpperInvariant(), cancellationToken);
        }

        var existing = await _messages.GetByProviderMessageIdAsync(payload.ProviderMessageId, cancellationToken);
        if (existing is not null)
        {
            return existing;
        }

        var message = new Message
        {
            OrganizationId = organizationId,
            Direction = "Inbound",
            Status = "Received",
            Intent = "CustomerCare",
            Priority = "Normal",
            FromNumber = normalizedFrom,
            ToNumber = PhoneNumberHelper.Normalize(payload.To),
            Body = body,
            ProviderMessageId = payload.ProviderMessageId,
            ProviderName = payload.ProviderName,
            SentAt = DateTimeOffset.UtcNow
        };

        var insight = await _intelligence.AnalyzeInboundAsync(message, cancellationToken);
        message.AiInsight = insight;
        message.Priority = insight.SuggestedPriority ?? message.Priority;

        await _messages.AddAsync(message, cancellationToken);
        await _messages.SaveChangesAsync(cancellationToken);
        await _audit.RecordEventAsync(message.Id, "AiAnalyzed", insight.Sentiment, cancellationToken: cancellationToken);

        return message;
    }

    public async Task UpdateDeliveryStatusAsync(string providerMessageId, string status, CancellationToken cancellationToken = default)
    {
        var message = await _messages.GetByProviderMessageIdAsync(providerMessageId, cancellationToken);
        if (message is null)
        {
            return;
        }

        message.Status = MapDeliveryStatus(status);
        if (message.Status == "Delivered")
        {
            message.DeliveredAt = DateTimeOffset.UtcNow;
        }

        message.UpdatedAt = DateTimeOffset.UtcNow;
        await _messages.SaveChangesAsync(cancellationToken);
        await _audit.RecordEventAsync(message.Id, "DeliveryUpdated", status, message.ProviderName, cancellationToken);
    }

    public async Task<PaginatedResult<MessageDto>> ListMessagesAsync(
        Guid organizationId, int page, int pageSize, string? direction, CancellationToken cancellationToken = default)
    {
        var (items, total) = await _messages.ListAsync(organizationId, page, pageSize, direction, cancellationToken);
        return new PaginatedResult<MessageDto>(items.Select(MapMessage).ToList(), total, page, pageSize);
    }

    public async Task<DashboardStatsDto> GetStatsAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        var stats = await _messages.GetStatsAsync(organizationId, cancellationToken);
        var deliveryRate = stats.Sent == 0 ? 0 : Math.Round((double)stats.Delivered / stats.Sent * 100, 1);
        return new DashboardStatsDto(
            stats.Total,
            stats.Sent,
            stats.Received,
            stats.Blocked,
            stats.Failed,
            stats.Contacts,
            deliveryRate,
            Math.Round(stats.AvgComplianceRisk, 2));
    }

    private static SendMessageResponse MapSendResponse(Message message) =>
        new(message.Id, message.Status, message.ComplianceDecision, message.ComplianceReason, message.ScheduledFor,
            message.AiInsight is null ? null : MapInsight(message.AiInsight));

    private static MessageDto MapMessage(Message message) =>
        new(message.Id, message.Direction, message.Status, message.Intent, message.Priority,
            message.FromNumber, message.ToNumber, message.Body, message.ProviderName, message.ComplianceDecision,
            message.CreatedAt, message.ScheduledFor, message.SentAt,
            message.AiInsight is null ? null : MapInsight(message.AiInsight));

    private static AiInsightDto MapInsight(AiInsight insight) =>
        new(insight.Sentiment, insight.SentimentScore, insight.ComplianceRiskScore,
            insight.SuggestedPriority, insight.ContentSuggestions, insight.RequiresHumanReview);

    private static string MapDeliveryStatus(string status) =>
        status.ToLowerInvariant() switch
        {
            "delivered" => "Delivered",
            "sent" => "Sent",
            "failed" or "undelivered" => "Failed",
            _ => "Processing"
        };
}

public record OutboundMessageJob(Guid MessageId);

public interface IMessageQueue
{
    Task PublishAsync(OutboundMessageJob job, CancellationToken cancellationToken = default);
}
