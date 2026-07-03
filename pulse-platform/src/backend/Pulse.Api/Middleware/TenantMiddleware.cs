using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Pulse.Application.Common;
using Pulse.Domain.Tenants;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Api.Middleware;

public class TenantContextMiddleware
{
    private readonly RequestDelegate _next;

    public TenantContextMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context, PulseDbContext db)
    {
        var tenantContext = await ResolveTenantContext(context, db);
        context.Items[nameof(ITenantContext)] = tenantContext;
        await _next(context);
    }

    private static async Task<ITenantContext> ResolveTenantContext(HttpContext context, PulseDbContext db)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var userId = Guid.TryParse(context.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? context.User.FindFirstValue("sub"), out var uid) ? uid : (Guid?)null;

            var workspaceIdClaim = context.User.FindFirstValue("workspace_id");
            var headerWorkspaceId = context.Request.Headers["X-Workspace-Id"].FirstOrDefault();
            var workspaceIdStr = headerWorkspaceId ?? workspaceIdClaim;

            if (Guid.TryParse(workspaceIdStr, out var workspaceId))
            {
                var permissions = context.User.FindAll("permission").Select(c => c.Value).ToList();
                return new TenantContext
                {
                    WorkspaceId = workspaceId,
                    UserId = userId,
                    Permissions = permissions
                };
            }
        }

        var apiKeyHeader = context.Request.Headers["X-Api-Key"].FirstOrDefault();
        if (!string.IsNullOrEmpty(apiKeyHeader) && apiKeyHeader.Length > 12)
        {
            var prefix = apiKeyHeader[..12];
            var apiKey = db.ApiKeys.FirstOrDefault(k => k.KeyPrefix == prefix && k.IsActive);
            if (apiKey != null && apiKey.Verify(apiKeyHeader))
            {
                if (apiKey.ExpiresAt.HasValue && apiKey.ExpiresAt < DateTimeOffset.UtcNow)
                    return new TenantContext { WorkspaceId = Guid.Empty };

                apiKey.RecordUsage();
                await db.SaveChangesAsync();

                return new TenantContext
                {
                    WorkspaceId = apiKey.WorkspaceId,
                    ApiKeyId = apiKey.Id,
                    Permissions = apiKey.Scopes.ToList()
                };
            }
        }

        return new TenantContext { WorkspaceId = Guid.Empty };
    }
}

public class TenantContextAccessor : ITenantContext
{
    private readonly IHttpContextAccessor _http;

    public TenantContextAccessor(IHttpContextAccessor http) => _http = http;

    private ITenantContext Inner =>
        _http.HttpContext?.Items[nameof(ITenantContext)] as ITenantContext
        ?? new TenantContext { WorkspaceId = Guid.Empty };

    public Guid WorkspaceId => Inner.WorkspaceId;
    public Guid? UserId => Inner.UserId;
    public Guid? ApiKeyId => Inner.ApiKeyId;
    public IReadOnlyList<string> Permissions => Inner.Permissions;
    public bool HasPermission(string permission) => Inner.HasPermission(permission);
}

public static class TenantMiddlewareExtensions
{
    public static IServiceCollection AddPulseAuth(this IServiceCollection services, IConfiguration config)
    {
        var jwtSecret = config["Jwt:Secret"] ?? "pulse-dev-secret-key-min-32-chars-long!!";
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = config["Jwt:Issuer"] ?? "pulse",
                    ValidAudience = config["Jwt:Audience"] ?? "pulse-api",
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret))
                };
            });

        services.AddAuthorization();
        services.AddHttpContextAccessor();
        services.AddScoped<ITenantContext, TenantContextAccessor>();
        return services;
    }

    public static IApplicationBuilder UseTenantContext(this IApplicationBuilder app) =>
        app.UseMiddleware<TenantContextMiddleware>();
}

public static class EndpointExtensions
{
    public static RouteGroupBuilder RequireTenant(this RouteGroupBuilder group)
    {
        group.AddEndpointFilter(async (context, next) =>
        {
            var tenant = context.HttpContext.RequestServices.GetRequiredService<ITenantContext>();
            if (tenant.WorkspaceId == Guid.Empty)
            {
                return Results.Json(new
                {
                    code = ErrorCodes.Unauthorized,
                    message = "Valid authentication and workspace context required"
                }, statusCode: 401);
            }
            return await next(context);
        });
        return group;
    }

    public static RouteHandlerBuilder RequirePermission(this RouteHandlerBuilder builder, string permission)
    {
        builder.AddEndpointFilter(async (context, next) =>
        {
            var tenant = context.HttpContext.RequestServices.GetRequiredService<ITenantContext>();
            if (!tenant.HasPermission(permission))
            {
                return Results.Json(new
                {
                    code = ErrorCodes.Forbidden,
                    message = $"Permission '{permission}' required"
                }, statusCode: 403);
            }
            return await next(context);
        });
        return builder;
    }
}
