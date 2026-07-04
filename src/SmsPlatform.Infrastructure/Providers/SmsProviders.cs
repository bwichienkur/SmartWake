using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using Twilio;
using Twilio.Rest.Api.V2010.Account;
using Twilio.Types;

namespace SmsPlatform.Infrastructure.Providers;

public class TwilioOptions
{
    public string AccountSid { get; set; } = string.Empty;
    public string AuthToken { get; set; } = string.Empty;
    public string FromNumber { get; set; } = string.Empty;
}

public class TwilioSmsProvider : ISmsProvider
{
    private readonly TwilioOptions _options;
    private readonly ILogger<TwilioSmsProvider> _logger;
    private bool _initialized;

    public TwilioSmsProvider(IOptions<TwilioOptions> options, ILogger<TwilioSmsProvider> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public string Name => "Twilio";

    public async Task<ProviderSendResult> SendAsync(ProviderSendRequest request, CancellationToken cancellationToken = default)
    {
        if (!IsConfigured())
        {
            return new ProviderSendResult(false, null, Name, "Failed", "Twilio not configured", 0);
        }

        EnsureInitialized();

        try
        {
            var message = await MessageResource.CreateAsync(
                body: request.Body,
                from: new PhoneNumber(request.From),
                to: new PhoneNumber(request.To),
                statusCallback: string.IsNullOrWhiteSpace(request.StatusCallbackUrl) ? null : new Uri(request.StatusCallbackUrl));

            return new ProviderSendResult(
                true,
                message.Sid,
                Name,
                message.Status.ToString(),
                null,
                0.0079m);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Twilio send failed");
            return new ProviderSendResult(false, null, Name, "Failed", ex.Message, 0);
        }
    }

    public Task<bool> HealthCheckAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult(IsConfigured());

    private bool IsConfigured() =>
        !string.IsNullOrWhiteSpace(_options.AccountSid) &&
        _options.AccountSid.StartsWith("AC", StringComparison.Ordinal) &&
        !string.IsNullOrWhiteSpace(_options.AuthToken) &&
        !string.IsNullOrWhiteSpace(_options.FromNumber);

    private void EnsureInitialized()
    {
        if (_initialized)
        {
            return;
        }

        TwilioClient.Init(_options.AccountSid, _options.AuthToken);
        _initialized = true;
    }
}

public class MockSmsProvider : ISmsProvider
{
    public string Name => "Mock";

    public Task<ProviderSendResult> SendAsync(ProviderSendRequest request, CancellationToken cancellationToken = default)
    {
        var id = $"mock_{Guid.NewGuid():N}";
        return Task.FromResult(new ProviderSendResult(true, id, Name, "Sent", null, 0.001m));
    }

    public Task<bool> HealthCheckAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult(true);
}

public class SmsProviderRouter : ISmsProviderRouter
{
    private readonly IEnumerable<ISmsProvider> _providers;
    private readonly ILogger<SmsProviderRouter> _logger;
    private readonly Dictionary<string, ProviderHealthState> _health = new();

    public SmsProviderRouter(IEnumerable<ISmsProvider> providers, ILogger<SmsProviderRouter> logger)
    {
        _providers = providers.OrderBy(p => p.Name == "Mock" ? 1 : 0).ToList();
        _logger = logger;
        foreach (var provider in _providers)
        {
            _health[provider.Name] = new ProviderHealthState(true, 1.0, 0);
        }
    }

    public async Task<ProviderSendResult> SendWithFailoverAsync(Domain.Entities.Message message, CancellationToken cancellationToken = default)
    {
        var body = message.OptimizedBody ?? message.Body;
        var request = new ProviderSendRequest(message.FromNumber, message.ToNumber, body, null);
        ProviderSendResult? lastResult = null;

        foreach (var provider in _providers.Where(p => IsHealthy(p.Name)))
        {
            var result = await provider.SendAsync(request, cancellationToken);
            UpdateHealth(provider.Name, result.Success);

            if (result.Success)
            {
                return result;
            }

            lastResult = result;
            _logger.LogWarning("Provider {Provider} failed for message {MessageId}: {Error}", provider.Name, message.Id, result.ErrorMessage);
        }

        return lastResult ?? new ProviderSendResult(false, null, "None", "Failed", "No providers available", 0);
    }

    public Task<IReadOnlyList<ProviderHealthDto>> GetHealthAsync(CancellationToken cancellationToken = default)
    {
        IReadOnlyList<ProviderHealthDto> result = _health
            .Select(kvp => new ProviderHealthDto(kvp.Key, kvp.Value.IsHealthy, kvp.Value.SuccessRate, kvp.Value.ConsecutiveFailures))
            .ToList();
        return Task.FromResult(result);
    }

    private bool IsHealthy(string name) =>
        _health.TryGetValue(name, out var state) && state.IsHealthy;

    private void UpdateHealth(string name, bool success)
    {
        if (!_health.TryGetValue(name, out var state))
        {
            state = new ProviderHealthState(true, 1.0, 0);
            _health[name] = state;
        }

        if (success)
        {
            state.ConsecutiveFailures = 0;
            state.IsHealthy = true;
            state.SuccessRate = Math.Min(1, state.SuccessRate * 0.9 + 0.1);
        }
        else
        {
            state.ConsecutiveFailures++;
            state.SuccessRate *= 0.8;
            if (state.ConsecutiveFailures >= 3)
            {
                state.IsHealthy = false;
            }
        }
    }

    private sealed class ProviderHealthState(bool isHealthy, double successRate, int consecutiveFailures)
    {
        public bool IsHealthy { get; set; } = isHealthy;
        public double SuccessRate { get; set; } = successRate;
        public int ConsecutiveFailures { get; set; } = consecutiveFailures;
    }
}
