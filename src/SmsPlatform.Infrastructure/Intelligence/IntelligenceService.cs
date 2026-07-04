using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Domain.Common;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Infrastructure.Intelligence;

public class IntelligenceOptions
{
    public string Provider { get; set; } = "Heuristic";
    public string? OpenAiApiKey { get; set; }
    public string OpenAiModel { get; set; } = "gpt-4o-mini";
    public string OpenAiEndpoint { get; set; } = "https://api.openai.com/v1/chat/completions";
}

public class IntelligenceService : IIntelligenceService
{
    private readonly IntelligenceOptions _options;
    private readonly HttpClient _http;
    private readonly ILogger<IntelligenceService> _logger;

    public IntelligenceService(IOptions<IntelligenceOptions> options, HttpClient http, ILogger<IntelligenceService> logger)
    {
        _options = options.Value;
        _http = http;
        _logger = logger;
    }

    public Task<AiInsight> AnalyzeOutboundAsync(Message message, CancellationToken cancellationToken = default) =>
        AnalyzeAsync(message, isOutbound: true, cancellationToken);

    public Task<AiInsight> AnalyzeInboundAsync(Message message, CancellationToken cancellationToken = default) =>
        AnalyzeAsync(message, isOutbound: false, cancellationToken);

    public async Task<AnalyzeContentResponse> AnalyzeContentAsync(AnalyzeContentRequest request, CancellationToken cancellationToken = default)
    {
        var issues = new List<string>();
        var risk = 0.0;

        if (request.Body.Length > 160)
        {
            issues.Add("Message exceeds single-segment length; may incur higher costs");
            risk += 0.1;
        }

        var lower = request.Body.ToLowerInvariant();
        if (lower.Contains("free") || lower.Contains("winner") || lower.Contains("click here"))
        {
            issues.Add("Content contains high-risk marketing language");
            risk += 0.4;
        }

        if (!request.Body.Contains("STOP", StringComparison.OrdinalIgnoreCase) && request.Intent is "Marketing" or "Events")
        {
            issues.Add("Marketing messages should include opt-out language (e.g., 'Reply STOP to opt out')");
            risk += 0.3;
        }

        if (_options.Provider == "OpenAI" && !string.IsNullOrWhiteSpace(_options.OpenAiApiKey))
        {
            try
            {
                var aiResult = await CallOpenAiAsync(
                    $"Analyze SMS compliance risk for intent '{request.Intent}': \"{request.Body}\". Return JSON with riskScore(0-1), issues[], suggestedBody.",
                    cancellationToken);
                if (aiResult is not null)
                {
                    return aiResult with { Issues = issues.Concat(aiResult.Issues).Distinct().ToList() };
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "OpenAI analysis failed, using heuristic fallback");
            }
        }

        var suggested = request.Intent is "Marketing" or "Events" && !request.Body.Contains("STOP", StringComparison.OrdinalIgnoreCase)
            ? $"{request.Body.TrimEnd('.')} Reply STOP to opt out."
            : null;

        return new AnalyzeContentResponse(
            Math.Min(1, risk),
            risk >= 0.7 ? "High" : risk >= 0.4 ? "Medium" : "Low",
            issues,
            suggested,
            request.Intent);
    }

    private async Task<AiInsight> AnalyzeAsync(Message message, bool isOutbound, CancellationToken cancellationToken)
    {
        var sentiment = AnalyzeSentiment(message.Body);
        var risk = CalculateComplianceRisk(message.Body, message.Intent);
        var priority = DeterminePriority(sentiment, risk, isOutbound);

        return new AiInsight
        {
            MessageId = message.Id,
            Sentiment = sentiment.Label,
            SentimentScore = sentiment.Score,
            ComplianceRiskScore = risk,
            SuggestedPriority = priority,
            ContentSuggestions = isOutbound ? SuggestContentImprovement(message.Body, message.Intent) : null,
            DetectedIntent = DetectIntent(message.Body),
            RequiresHumanReview = risk >= ComplianceConstants.HighComplianceRiskThreshold || sentiment.Label == "Urgent"
        };
    }

    private async Task<AnalyzeContentResponse?> CallOpenAiAsync(string prompt, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, _options.OpenAiEndpoint);
        request.Headers.Add("Authorization", $"Bearer {_options.OpenAiApiKey}");
        request.Content = JsonContent.Create(new
        {
            model = _options.OpenAiModel,
            messages = new[] { new { role = "user", content = prompt } },
            response_format = new { type = "json_object" }
        });

        var response = await _http.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken);
        var content = json.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
        if (string.IsNullOrWhiteSpace(content))
        {
            return null;
        }

        var parsed = JsonSerializer.Deserialize<JsonElement>(content);
        var issues = parsed.TryGetProperty("issues", out var issuesEl)
            ? issuesEl.EnumerateArray().Select(x => x.GetString() ?? "").Where(x => x.Length > 0).ToList()
            : [];
        return new AnalyzeContentResponse(
            parsed.GetProperty("riskScore").GetDouble(),
            "AI",
            issues,
            parsed.TryGetProperty("suggestedBody", out var sb) ? sb.GetString() : null,
            null);
    }

    private static (string Label, double Score) AnalyzeSentiment(string body)
    {
        var lower = body.ToLowerInvariant();
        string[] urgent = ["urgent", "emergency", "immediately", "asap", "help", "unacceptable", "waiting"];
        string[] negative = ["angry", "frustrated", "terrible", "worst", "complaint", "refund", "cancel"];
        string[] positive = ["thank", "great", "awesome", "perfect", "love", "appreciate"];

        if (urgent.Any(lower.Contains))
        {
            return ("Urgent", 0.9);
        }

        if (negative.Any(lower.Contains))
        {
            return ("Negative", 0.75);
        }

        if (positive.Any(lower.Contains))
        {
            return ("Positive", 0.8);
        }

        return ("Neutral", 0.5);
    }

    private static double CalculateComplianceRisk(string body, string intent)
    {
        var risk = 0.0;
        var lower = body.ToLowerInvariant();

        if (intent is "Marketing" or "Events")
        {
            risk += 0.2;
            if (!body.Contains("STOP", StringComparison.OrdinalIgnoreCase))
            {
                risk += 0.3;
            }
        }

        if (lower.Contains("free") || lower.Contains("winner") || lower.Contains("100%"))
        {
            risk += 0.35;
        }

        if (body.Length > 320)
        {
            risk += 0.1;
        }

        return Math.Min(1, risk);
    }

    private static string DeterminePriority((string Label, double Score) sentiment, double risk, bool isOutbound)
    {
        if (!isOutbound && (sentiment.Label is "Urgent" or "Negative" || risk >= 0.7))
        {
            return "High";
        }

        if (sentiment.Label == "Urgent")
        {
            return "Critical";
        }

        return "Normal";
    }

    private static string? SuggestContentImprovement(string body, string intent)
    {
        if (intent is "Marketing" or "Events" && !body.Contains("STOP", StringComparison.OrdinalIgnoreCase))
        {
            return $"{body.TrimEnd('.')}. Reply STOP to opt out.";
        }

        return null;
    }

    private static string DetectIntent(string body)
    {
        var lower = body.ToLowerInvariant();
        if (lower.Contains("code") || lower.Contains("otp") || lower.Contains("verification"))
        {
            return "Otp";
        }

        if (lower.Contains("appointment") || lower.Contains("reminder"))
        {
            return "Notification";
        }

        if (lower.Contains("sale") || lower.Contains("offer") || lower.Contains("discount"))
        {
            return "Marketing";
        }

        return "CustomerCare";
    }
}
