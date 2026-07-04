using Microsoft.EntityFrameworkCore;
using SmsPlatform.Domain.Entities;

namespace SmsPlatform.Infrastructure.Persistence;

public class SmsDbContext : DbContext
{
    public SmsDbContext(DbContextOptions<SmsDbContext> options) : base(options) { }

    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<ApiKey> ApiKeys => Set<ApiKey>();
    public DbSet<Contact> Contacts => Set<Contact>();
    public DbSet<Campaign> Campaigns => Set<Campaign>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<AiInsight> AiInsights => Set<AiInsight>();
    public DbSet<MessageEvent> MessageEvents => Set<MessageEvent>();
    public DbSet<OptOutRecord> OptOutRecords => Set<OptOutRecord>();
    public DbSet<WebhookSubscription> WebhookSubscriptions => Set<WebhookSubscription>();
    public DbSet<ProviderHealth> ProviderHealthRecords => Set<ProviderHealth>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Organization>(e =>
        {
            e.HasIndex(x => x.Slug).IsUnique();
        });

        modelBuilder.Entity<ApiKey>(e =>
        {
            e.HasIndex(x => x.KeyPrefix);
            e.Property(x => x.Scopes).HasConversion(
                v => string.Join(',', v),
                v => v.Split(',', StringSplitOptions.RemoveEmptyEntries));
        });

        modelBuilder.Entity<Contact>(e =>
        {
            e.HasIndex(x => new { x.OrganizationId, x.PhoneNumber }).IsUnique();
        });

        modelBuilder.Entity<Message>(e =>
        {
            e.HasIndex(x => x.CorrelationId);
            e.HasIndex(x => new { x.OrganizationId, x.IdempotencyKey });
            e.HasIndex(x => x.ProviderMessageId);
            e.HasIndex(x => x.CreatedAt);
            e.HasOne(x => x.AiInsight).WithOne(x => x.Message).HasForeignKey<AiInsight>(x => x.MessageId);
        });

        modelBuilder.Entity<OptOutRecord>(e =>
        {
            e.HasIndex(x => new { x.OrganizationId, x.PhoneNumber }).IsUnique();
        });

        modelBuilder.Entity<WebhookSubscription>(e =>
        {
            e.Property(x => x.Events).HasConversion(
                v => string.Join(',', v),
                v => v.Split(',', StringSplitOptions.RemoveEmptyEntries));
        });
    }
}
