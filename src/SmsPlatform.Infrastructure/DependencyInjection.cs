using System.Security.Cryptography;
using System.Text;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Application.Services;
using SmsPlatform.Infrastructure.Compliance;
using SmsPlatform.Infrastructure.Intelligence;
using SmsPlatform.Infrastructure.Messaging;
using SmsPlatform.Infrastructure.Persistence;
using SmsPlatform.Infrastructure.Persistence.Repositories;
using SmsPlatform.Infrastructure.Providers;
using SmsPlatform.Infrastructure.Security;

namespace SmsPlatform.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=smsplatform;Username=sms;Password=sms";

        services.AddDbContext<SmsDbContext>(options =>
        {
            if (configuration.GetValue<bool>("UseSqlite"))
            {
                options.UseSqlite(configuration.GetConnectionString("Sqlite") ?? "Data Source=smsplatform.db");
            }
            else
            {
                options.UseNpgsql(connectionString);
            }
        });

        services.Configure<TwilioOptions>(configuration.GetSection("Twilio"));
        services.Configure<IntelligenceOptions>(configuration.GetSection("Intelligence"));

        services.AddScoped<IMessageRepository, MessageRepository>();
        services.AddScoped<IOrganizationRepository, OrganizationRepository>();
        services.AddScoped<IContactRepository, ContactRepository>();
        services.AddScoped<IOptOutRepository, OptOutRepository>();
        services.AddScoped<IComplianceStatsRepository, ComplianceStatsRepository>();
        services.AddScoped<IAuditService, AuditService>();
        services.AddScoped<IComplianceEngine, ComplianceEngine>();
        services.AddScoped<IIntelligenceService, IntelligenceService>();
        services.AddScoped<IMessageService, MessageService>();
        services.AddScoped<IContactService, ContactService>();
        services.AddScoped<IComplianceReportService, ComplianceReportService>();
        services.AddScoped<IApiKeyValidator, ApiKeyValidator>();
        services.AddScoped<ISmsProviderRouter, SmsProviderRouter>();
        services.AddScoped<ISmsProvider, TwilioSmsProvider>();
        services.AddScoped<ISmsProvider, MockSmsProvider>();
        services.AddHttpClient<IntelligenceService>();

        var rabbitHost = configuration["RabbitMQ:Host"];
        if (!string.IsNullOrWhiteSpace(rabbitHost))
        {
            services.AddMassTransit(x =>
            {
                x.AddConsumer<OutboundMessageConsumer>();
                x.UsingRabbitMq((context, cfg) =>
                {
                    cfg.Host(rabbitHost, h =>
                    {
                        h.Username(configuration["RabbitMQ:Username"] ?? "guest");
                        h.Password(configuration["RabbitMQ:Password"] ?? "guest");
                    });
                    cfg.ConfigureEndpoints(context);
                });
            });
            services.AddScoped<IMessageQueue, MassTransitMessageQueue>();
        }
        else
        {
            services.AddScoped<IMessageQueue, InProcessMessageQueue>();
        }

        return services;
    }
}

public class ApiKeyValidator : IApiKeyValidator
{
    private readonly SmsDbContext _db;

    public ApiKeyValidator(SmsDbContext db) => _db = db;

    public async Task<Domain.Entities.Organization?> ValidateAsync(string apiKey, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(apiKey) || apiKey.Length < 12)
        {
            return null;
        }

        var prefix = apiKey[..8];
        var candidates = await _db.ApiKeys
            .Include(k => k.Organization)
            .Where(k => k.KeyPrefix == prefix && k.IsActive)
            .ToListAsync(cancellationToken);

        foreach (var candidate in candidates)
        {
            if (candidate.ExpiresAt is not null && candidate.ExpiresAt < DateTimeOffset.UtcNow)
            {
                continue;
            }

            if (VerifyHash(apiKey, candidate.KeyHash))
            {
                return candidate.Organization.IsActive ? candidate.Organization : null;
            }
        }

        return null;
    }

    public static string HashKey(string apiKey)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(apiKey));
        return Convert.ToHexString(bytes);
    }

    private static bool VerifyHash(string apiKey, string hash) =>
        HashKey(apiKey).Equals(hash, StringComparison.OrdinalIgnoreCase);
}

public static class ApiKeyGenerator
{
    public static (string RawKey, string Hash, string Prefix) Generate()
    {
        var raw = $"sms_{Convert.ToHexString(RandomNumberGenerator.GetBytes(24)).ToLowerInvariant()}";
        return (raw, ApiKeyValidator.HashKey(raw), raw[..8]);
    }
}
