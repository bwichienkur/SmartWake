using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Infrastructure.Analytics;
using Pulse.Infrastructure.Audit.Services;
using Pulse.Infrastructure.Auth.Services;
using Pulse.Infrastructure.Campaigns.Services;
using Pulse.Infrastructure.Common;
using Pulse.Infrastructure.Contacts.Services;
using Pulse.Domain.Contacts;
using Pulse.Domain.Tenants;
using Pulse.Infrastructure.Persistence;
using Pulse.Infrastructure.Reporting.Services;

namespace Pulse.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddPulseInfrastructure(
        this IServiceCollection services,
        string connectionString)
    {
        services.AddDbContext<PulseDbContext>(options =>
            options.UseNpgsql(connectionString, npgsql =>
            {
                npgsql.MigrationsAssembly(typeof(PulseDbContext).Assembly.FullName);
                npgsql.EnableRetryOnFailure(3);
            }));

        services.AddScoped<IOutboxPublisher, OutboxPublisher>();
        services.AddScoped<IAnalyticsStore, PostgresAnalyticsStore>();
        services.AddScoped<IContactService, ContactService>();
        services.AddScoped<ICampaignService, CampaignService>();
        services.AddScoped<IEventIngestionService, EventIngestionService>();
        services.AddScoped<IReportingService, ReportingService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IAuditService, AuditService>();

        return services;
    }

    public static async Task MigrateAndSeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PulseDbContext>();
        await db.Database.MigrateAsync();
        await DataSeeder.SeedAsync(db);
    }
}

public static class DataSeeder
{
    public static async Task SeedAsync(PulseDbContext db)
    {
        if (await db.Organizations.AnyAsync()) return;

        var org = Organization.Create("Pulse Demo", "pulse-demo", "enterprise");
        var workspace = Workspace.Create(org.Id, "Main Workspace", "main");
        var brand = Brand.Create(workspace.Id, "Pulse Demo", isDefault: true);
        var adminRole = Role.CreateSystemRole("Admin", Permissions.All);
        var user = User.Create(
            "admin@pulse.demo",
            BCrypt.Net.BCrypt.HashPassword("PulseDemo123!"),
            "Admin",
            "User");
        var membership = WorkspaceMembership.Create(workspace.Id, user.Id, adminRole.Id);

        db.Organizations.Add(org);
        db.Workspaces.Add(workspace);
        db.Brands.Add(brand);
        db.Roles.Add(adminRole);
        db.Users.Add(user);
        db.WorkspaceMemberships.Add(membership);

        // Seed sample contacts
        var contacts = new[]
        {
            Contact.Create(workspace.Id, "alice@example.com", "Alice", "Johnson"),
            Contact.Create(workspace.Id, "bob@example.com", "Bob", "Smith"),
            Contact.Create(workspace.Id, "carol@example.com", "Carol", "Williams")
        };
        contacts[0].LifecycleStage = "customer";
        contacts[0].Source = "website";
        contacts[1].LifecycleStage = "lead";
        contacts[2].LifecycleStage = "subscriber";

        db.Contacts.AddRange(contacts);
        await db.SaveChangesAsync();
    }
}
