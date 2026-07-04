namespace SmsPlatform.Application.Interfaces;

public record ProviderSendResult(
    bool Success,
    string? ProviderMessageId,
    string ProviderName,
    string Status,
    string? ErrorMessage,
    decimal EstimatedCost);
