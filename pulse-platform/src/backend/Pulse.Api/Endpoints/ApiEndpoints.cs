using Pulse.Application.Auth.Dtos;
using Pulse.Application.Campaigns.Dtos;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Application.Contacts.Dtos;
using Pulse.Application.Reporting.Dtos;
using Pulse.Domain.Tenants;
using Pulse.Api.Middleware;

namespace Pulse.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Auth");

        group.MapPost("/register", async (RegisterRequest req, IAuthService auth) =>
            Results.Ok(await auth.RegisterAsync(req))).AllowAnonymous();

        group.MapPost("/login", async (LoginRequest req, IAuthService auth) =>
            Results.Ok(await auth.LoginAsync(req))).AllowAnonymous();

        group.MapGet("/me", async (IAuthService auth) =>
            Results.Ok(await auth.GetProfileAsync())).RequireAuthorization();
    }
}

public static class ContactEndpoints
{
    public static void MapContactEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/contacts")
            .WithTags("Contacts")
            .RequireAuthorization()
            .RequireTenant();

        group.MapGet("/", async (string? search, string? status, string? tag, string? after, int? limit, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsRead)) return Results.Forbid();
            return Results.Ok(await contacts.ListAsync(new ContactListQuery(search, status, tag, after, limit ?? 50)));
        });

        group.MapGet("/{id:guid}", async (Guid id, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsRead)) return Results.Forbid();
            var contact = await contacts.GetByIdAsync(id);
            return contact == null ? Results.NotFound() : Results.Ok(contact);
        });

        group.MapPost("/", async (CreateContactRequest req, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsWrite)) return Results.Forbid();
            var contact = await contacts.CreateAsync(req);
            return Results.Created($"/api/v1/contacts/{contact.Id}", contact);
        });

        group.MapPatch("/{id:guid}", async (Guid id, UpdateContactRequest req, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsWrite)) return Results.Forbid();
            return Results.Ok(await contacts.UpdateAsync(id, req));
        });

        group.MapDelete("/{id:guid}", async (Guid id, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsDelete)) return Results.Forbid();
            await contacts.DeleteAsync(id);
            return Results.NoContent();
        });

        group.MapPost("/{id:guid}/events", async (Guid id, TrackEventRequest req, ITenantContext tenant, IContactService contacts) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsWrite)) return Results.Forbid();
            return Results.Ok(await contacts.TrackEventAsync(id, req));
        });
    }
}

public static class EventEndpoints
{
    public static void MapEventEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/events")
            .WithTags("Events")
            .RequireAuthorization()
            .RequireTenant();

        group.MapPost("/", async (IngestEventRequest req, ITenantContext tenant, IEventIngestionService events) =>
        {
            if (!tenant.HasPermission(Permissions.ContactsWrite)) return Results.Forbid();
            return Results.Ok(await events.IngestEventAsync(req));
        });
    }
}

public static class CampaignEndpoints
{
    public static void MapCampaignEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/campaigns")
            .WithTags("Campaigns")
            .RequireAuthorization()
            .RequireTenant();

        group.MapGet("/", async (string? status, string? search, string? after, int? limit, ITenantContext tenant, ICampaignService campaigns) =>
        {
            if (!tenant.HasPermission(Permissions.CampaignsRead)) return Results.Forbid();
            return Results.Ok(await campaigns.ListAsync(new CampaignListQuery(status, search, after, limit ?? 50)));
        });

        group.MapGet("/{id:guid}", async (Guid id, ITenantContext tenant, ICampaignService campaigns) =>
        {
            if (!tenant.HasPermission(Permissions.CampaignsRead)) return Results.Forbid();
            var campaign = await campaigns.GetByIdAsync(id);
            return campaign == null ? Results.NotFound() : Results.Ok(campaign);
        });

        group.MapPost("/", async (CreateCampaignRequest req, ITenantContext tenant, ICampaignService campaigns) =>
        {
            if (!tenant.HasPermission(Permissions.CampaignsWrite)) return Results.Forbid();
            var campaign = await campaigns.CreateAsync(req);
            return Results.Created($"/api/v1/campaigns/{campaign.Id}", campaign);
        });

        group.MapPatch("/{id:guid}", async (Guid id, UpdateCampaignRequest req, ITenantContext tenant, ICampaignService campaigns) =>
        {
            if (!tenant.HasPermission(Permissions.CampaignsWrite)) return Results.Forbid();
            return Results.Ok(await campaigns.UpdateAsync(id, req));
        });

        group.MapDelete("/{id:guid}", async (Guid id, ITenantContext tenant, ICampaignService campaigns) =>
        {
            if (!tenant.HasPermission(Permissions.CampaignsWrite)) return Results.Forbid();
            await campaigns.DeleteAsync(id);
            return Results.NoContent();
        });
    }
}

public static class ReportingEndpoints
{
    public static void MapReportingEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/reports")
            .WithTags("Reporting")
            .RequireAuthorization()
            .RequireTenant();

        group.MapGet("/executive", async (DateTimeOffset? from, DateTimeOffset? to, ITenantContext tenant, IReportingService reporting) =>
        {
            if (!tenant.HasPermission(Permissions.ReportsRead)) return Results.Forbid();
            return Results.Ok(await reporting.GetExecutiveDashboardAsync(new ReportQuery(from, to)));
        });

        group.MapGet("/campaigns/{id:guid}", async (Guid id, ITenantContext tenant, IReportingService reporting) =>
        {
            if (!tenant.HasPermission(Permissions.ReportsRead)) return Results.Forbid();
            return Results.Ok(await reporting.GetCampaignPerformanceAsync(id));
        });
    }
}

public static class HealthEndpoints
{
    public static void MapHealthEndpoints(this WebApplication app)
    {
        app.MapGet("/health", () => Results.Ok(new { status = "healthy", service = "pulse-api" }))
            .AllowAnonymous().WithTags("Health");
        app.MapGet("/ready", () => Results.Ok(new { status = "ready" }))
            .AllowAnonymous().WithTags("Health");
    }
}
