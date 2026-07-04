using Microsoft.EntityFrameworkCore;
using SmsPlatform.Domain.Entities;
using SmsPlatform.Infrastructure.Persistence;
using SmsPlatform.Infrastructure.Security;

namespace SmsPlatform.Infrastructure.Persistence;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(SmsDbContext db)
    {
        if (await db.Organizations.AnyAsync())
        {
            return;
        }

        var org = new Organization
        {
            Name = "Demo Enterprise",
            Slug = "demo-enterprise",
            DailyMessageLimit = 50_000,
            RateLimitPerMinute = 500
        };

        var (rawKey, hash, prefix) = ApiKeyGenerator.Generate();
        var apiKey = new ApiKey
        {
            Organization = org,
            Name = "Default API Key",
            KeyHash = hash,
            KeyPrefix = prefix
        };

        db.Organizations.Add(org);
        db.ApiKeys.Add(apiKey);
        db.Campaigns.Add(new Campaign
        {
            Organization = org,
            Name = "Transactional Notifications",
            UseCase = "transactional",
            IsRegistered = true,
            TenDlcCampaignId = "DEMO-CAMP-001"
        });

        db.Contacts.AddRange(
            new Contact { Organization = org, Name = "Alice Johnson", PhoneNumber = "+15551234567", ConsentStatus = "OptedIn", ConsentRecordedAt = DateTimeOffset.UtcNow },
            new Contact { Organization = org, Name = "Bob Smith", PhoneNumber = "+15559876543", ConsentStatus = "OptedIn", ConsentRecordedAt = DateTimeOffset.UtcNow });

        await db.SaveChangesAsync();

        Console.WriteLine("=================================================");
        Console.WriteLine(" SMS Platform seeded successfully");
        Console.WriteLine($" Demo API Key: {rawKey}");
        Console.WriteLine(" Store this key securely — it won't be shown again.");
        Console.WriteLine("=================================================");
    }
}
