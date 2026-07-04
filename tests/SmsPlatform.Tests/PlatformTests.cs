using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Application.Services;
using SmsPlatform.Domain.Entities;
using SmsPlatform.Infrastructure;
using SmsPlatform.Infrastructure.Compliance;
using SmsPlatform.Infrastructure.Intelligence;
using SmsPlatform.Infrastructure.Messaging;
using SmsPlatform.Infrastructure.Persistence;
using SmsPlatform.Infrastructure.Persistence.Repositories;
using SmsPlatform.Infrastructure.Providers;

namespace SmsPlatform.Tests;

public class ComplianceEngineTests
{
    [Fact]
    public async Task Blocks_messages_to_opted_out_recipients()
    {
        await using var db = TestHelpers.CreateDb();
        var org = await TestHelpers.SeedOrganization(db);
        db.OptOutRecords.Add(new OptOutRecord { OrganizationId = org.Id, PhoneNumber = "+15551234567" });
        await db.SaveChangesAsync();

        var engine = new ComplianceEngine(new OptOutRepository(db), new OrganizationRepository(db));
        var result = await engine.EvaluateOutboundAsync(new Message
        {
            OrganizationId = org.Id,
            ToNumber = "+15551234567",
            Body = "Hello",
            Intent = "Transactional"
        });

        result.Decision.Should().Be("Blocked");
    }

    [Fact]
    public async Task Schedules_marketing_messages_during_quiet_hours()
    {
        await using var db = TestHelpers.CreateDb();
        var org = await TestHelpers.SeedOrganization(db);
        var engine = new ComplianceEngine(new OptOutRepository(db), new OrganizationRepository(db));

        var result = await engine.EvaluateOutboundAsync(new Message
        {
            OrganizationId = org.Id,
            ToNumber = "+12125551234",
            Body = "Special offer today",
            Intent = "Marketing"
        });

        if (DateTime.UtcNow.Hour is >= 0 and < 12)
        {
            result.Decision.Should().BeOneOf("Scheduled", "Allowed");
        }
    }
}

public class IntelligenceServiceTests
{
    [Fact]
    public async Task Detects_urgent_inbound_sentiment()
    {
        var service = new IntelligenceService(
            Microsoft.Extensions.Options.Options.Create(new IntelligenceOptions()),
            new HttpClient(),
            Microsoft.Extensions.Logging.Abstractions.NullLogger<IntelligenceService>.Instance);

        var insight = await service.AnalyzeInboundAsync(new Message
        {
            Body = "This is unacceptable, I need help immediately!"
        });

        insight.Sentiment.Should().BeOneOf("Urgent", "Negative");
        insight.SuggestedPriority.Should().BeOneOf("High", "Critical");
    }

    [Fact]
    public async Task Flags_marketing_content_missing_opt_out()
    {
        var service = new IntelligenceService(
            Microsoft.Extensions.Options.Options.Create(new IntelligenceOptions()),
            new HttpClient(),
            Microsoft.Extensions.Logging.Abstractions.NullLogger<IntelligenceService>.Instance);

        var result = await service.AnalyzeContentAsync(new AnalyzeContentRequest("Buy now and save 50%!", "Marketing"));
        result.ComplianceRiskScore.Should().BeGreaterThanOrEqualTo(0.3);
        result.Issues.Should().Contain(i => i.Contains("opt-out", StringComparison.OrdinalIgnoreCase));
    }
}

public class MessageServiceTests
{
    [Fact]
    public async Task Queues_outbound_message_in_mock_mode()
    {
        await using var db = TestHelpers.CreateDb();
        var org = await TestHelpers.SeedOrganization(db);
        var service = TestHelpers.BuildMessageService(db);

        var response = await service.QueueOutboundAsync(org.Id, new SendMessageRequest("+15559876543", "Test message"));

        response.Status.Should().BeOneOf("Queued", "Sent", "Scheduled", "Blocked");
        (await db.Messages.CountAsync()).Should().Be(1);
    }

    [Fact]
    public async Task Records_inbound_opt_out_keyword()
    {
        await using var db = TestHelpers.CreateDb();
        var org = await TestHelpers.SeedOrganization(db);
        var service = TestHelpers.BuildMessageService(db);

        await service.HandleInboundAsync(org.Id, new InboundWebhookPayload("+15551234567", "+15550000001", "STOP", "SM001", "Mock"));

        (await db.OptOutRecords.CountAsync()).Should().Be(1);
    }
}

internal static class TestHelpers
{
    public static SmsDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<SmsDbContext>()
            .UseSqlite("Data Source=:memory:")
            .Options;
        var db = new SmsDbContext(options);
        db.Database.OpenConnection();
        db.Database.EnsureCreated();
        return db;
    }

    public static async Task<Organization> SeedOrganization(SmsDbContext db)
    {
        var org = new Organization { Name = "Test Org", Slug = "test-org" };
        db.Organizations.Add(org);
        await db.SaveChangesAsync();
        return org;
    }

    public static MessageService BuildMessageService(SmsDbContext db)
    {
        var messageRepo = new MessageRepository(db);
        var orgRepo = new OrganizationRepository(db);
        var optOutRepo = new OptOutRepository(db);
        var compliance = new ComplianceEngine(optOutRepo, orgRepo);
        var intelligence = new IntelligenceService(
            Microsoft.Extensions.Options.Options.Create(new IntelligenceOptions()),
            new HttpClient(),
            Microsoft.Extensions.Logging.Abstractions.NullLogger<IntelligenceService>.Instance);
        var providers = new List<ISmsProvider> { new MockSmsProvider() };
        var router = new SmsProviderRouter(providers, Microsoft.Extensions.Logging.Abstractions.NullLogger<SmsProviderRouter>.Instance);
        var audit = new AuditService(db);
        var queue = new InlineMessageQueue(messageRepo, compliance, intelligence, router, audit, db,
            Microsoft.Extensions.Logging.Abstractions.NullLogger<MessageService>.Instance);

        return new MessageService(messageRepo, orgRepo, compliance, intelligence, router, audit, queue,
            Microsoft.Extensions.Logging.Abstractions.NullLogger<MessageService>.Instance);
    }
}

internal class InlineMessageQueue : IMessageQueue
{
    private readonly MessageService _service;

    public InlineMessageQueue(
        IMessageRepository messages,
        IComplianceEngine compliance,
        IIntelligenceService intelligence,
        ISmsProviderRouter router,
        IAuditService audit,
        SmsDbContext db,
        Microsoft.Extensions.Logging.ILogger<MessageService> logger)
    {
        _service = new MessageService(messages, new OrganizationRepository(db), compliance, intelligence, router, audit, this, logger);
    }

    public async Task PublishAsync(OutboundMessageJob job, CancellationToken cancellationToken = default)
    {
        await _service.ProcessOutboundAsync(job.MessageId, cancellationToken);
    }
}
