using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Pulse.Domain.Audit;
using Pulse.Domain.Campaigns;
using Pulse.Domain.Contacts;
using Pulse.Domain.Events;
using Pulse.Domain.Tenants;

namespace Pulse.Infrastructure.Persistence;

public class PulseDbContext : DbContext
{
    public PulseDbContext(DbContextOptions<PulseDbContext> options) : base(options) { }

    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<Workspace> Workspaces => Set<Workspace>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<WorkspaceMembership> WorkspaceMemberships => Set<WorkspaceMembership>();
    public DbSet<ApiKey> ApiKeys => Set<ApiKey>();
    public DbSet<Contact> Contacts => Set<Contact>();
    public DbSet<ContactTag> ContactTags => Set<ContactTag>();
    public DbSet<ContactList> ContactLists => Set<ContactList>();
    public DbSet<ContactListMembership> ContactListMemberships => Set<ContactListMembership>();
    public DbSet<ContactEvent> ContactEvents => Set<ContactEvent>();
    public DbSet<ConsentRecord> ConsentRecords => Set<ConsentRecord>();
    public DbSet<Campaign> Campaigns => Set<Campaign>();
    public DbSet<CampaignVersion> CampaignVersions => Set<CampaignVersion>();
    public DbSet<CampaignSend> CampaignSends => Set<CampaignSend>();
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
    public DbSet<InboxMessage> InboxMessages => Set<InboxMessage>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("uuid-ossp");

        ConfigureTenants(modelBuilder);
        ConfigureContacts(modelBuilder);
        ConfigureCampaigns(modelBuilder);
        ConfigureEvents(modelBuilder);
        ConfigureAudit(modelBuilder);
    }

    private static void ConfigureTenants(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Organization>(e =>
        {
            e.ToTable("organizations");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.Slug).IsUnique();
            e.Property(x => x.Name).HasMaxLength(256).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(128).IsRequired();
        });

        modelBuilder.Entity<Workspace>(e =>
        {
            e.ToTable("workspaces");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.OrganizationId, x.Slug }).IsUnique();
            e.Property(x => x.Name).HasMaxLength(256).IsRequired();
        });

        modelBuilder.Entity<Brand>(e =>
        {
            e.ToTable("brands");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.WorkspaceId);
        });

        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("users");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.Email).HasMaxLength(320).IsRequired();
        });

        modelBuilder.Entity<Role>(e =>
        {
            e.ToTable("roles");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(128).IsRequired();
            e.Property(x => x.PermissionsInternal).HasColumnName("permissions_json")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new());
        });

        modelBuilder.Entity<WorkspaceMembership>(e =>
        {
            e.ToTable("workspace_memberships");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.WorkspaceId, x.UserId }).IsUnique();
        });

        modelBuilder.Entity<ApiKey>(e =>
        {
            e.ToTable("api_keys");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.KeyPrefix);
            e.Property(x => x.ScopesInternal).HasColumnName("scopes_json")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new());
        });
    }

    private static void ConfigureContacts(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Contact>(e =>
        {
            e.ToTable("contacts");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.WorkspaceId, x.Email }).IsUnique()
                .HasFilter("is_deleted = false");
            e.HasIndex(x => new { x.WorkspaceId, x.Status });
            e.HasIndex(x => new { x.WorkspaceId, x.CreatedAt });
            e.Property(x => x.Email).HasMaxLength(320).IsRequired();
            e.Property(x => x.CustomFields).HasColumnName("custom_fields_json")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<Dictionary<string, object?>>(v, (JsonSerializerOptions?)null) ?? new())
                .Metadata.SetValueComparer(new ValueComparer<Dictionary<string, object?>>(
                    (a, b) => JsonSerializer.Serialize(a, (JsonSerializerOptions?)null) == JsonSerializer.Serialize(b, (JsonSerializerOptions?)null),
                    v => v == null ? 0 : JsonSerializer.Serialize(v, (JsonSerializerOptions?)null).GetHashCode(),
                    v => v == null ? new() : new Dictionary<string, object?>(v)));
        });

        modelBuilder.Entity<ContactEvent>(e =>
        {
            e.ToTable("contact_events");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.WorkspaceId, x.ContactId, x.OccurredAt });
            e.HasIndex(x => new { x.WorkspaceId, x.IdempotencyKey }).IsUnique()
                .HasFilter("idempotency_key IS NOT NULL");
        });

        modelBuilder.Entity<ContactList>(e => e.ToTable("contact_lists"));
        modelBuilder.Entity<ContactTag>(e => e.ToTable("contact_tags"));
        modelBuilder.Entity<ContactListMembership>(e => e.ToTable("contact_list_memberships"));
        modelBuilder.Entity<ConsentRecord>(e => e.ToTable("consent_records"));
    }

    private static void ConfigureCampaigns(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Campaign>(e =>
        {
            e.ToTable("campaigns");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.WorkspaceId, x.Status });
            e.Property(x => x.Name).HasMaxLength(512).IsRequired();
        });

        modelBuilder.Entity<CampaignVersion>(e => e.ToTable("campaign_versions"));
        modelBuilder.Entity<CampaignSend>(e =>
        {
            e.ToTable("campaign_sends");
            e.HasIndex(x => new { x.WorkspaceId, x.CampaignId, x.ContactId });
        });
    }

    private static void ConfigureEvents(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<OutboxMessage>(e =>
        {
            e.ToTable("outbox_messages");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.PublishedAt).HasFilter("published_at IS NULL");
        });

        modelBuilder.Entity<InboxMessage>(e =>
        {
            e.ToTable("inbox_messages");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.MessageId, x.ConsumerGroup }).IsUnique();
        });
    }

    private static void ConfigureAudit(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AuditLog>(e =>
        {
            e.ToTable("audit_logs");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.WorkspaceId, x.CreatedAt });
            e.HasIndex(x => new { x.WorkspaceId, x.EntityType, x.EntityId });
        });
    }
}
