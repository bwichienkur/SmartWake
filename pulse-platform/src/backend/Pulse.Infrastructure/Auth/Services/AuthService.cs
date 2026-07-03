using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Pulse.Application.Auth.Dtos;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Domain.Tenants;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Auth.Services;

public class AuthService : IAuthService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IConfiguration _config;
    private readonly IAuditService _audit;

    public AuthService(PulseDbContext db, ITenantContext tenant, IConfiguration config, IAuditService audit)
    {
        _db = db;
        _tenant = tenant;
        _config = config;
        _audit = audit;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var email = request.Email.ToLowerInvariant().Trim();
        var user = _db.Users.FirstOrDefault(u => u.Email == email && u.IsActive)
            ?? throw new AppException(ErrorCodes.Unauthorized, "Invalid credentials", 401);

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new AppException(ErrorCodes.Unauthorized, "Invalid credentials", 401);

        user.RecordLogin();

        var membership = _db.WorkspaceMemberships
            .Where(m => m.UserId == user.Id && m.IsActive)
            .OrderBy(m => m.CreatedAt)
            .FirstOrDefault()
            ?? throw new AppException(ErrorCodes.Forbidden, "No workspace access", 403);

        var workspace = await _db.Workspaces.FindAsync([membership.WorkspaceId], ct)
            ?? throw new AppException(ErrorCodes.Forbidden, "Workspace not found", 403);

        var role = await _db.Roles.FindAsync([membership.RoleId], ct);
        var permissions = role?.Permissions.ToList() ?? [];

        var token = GenerateToken(user, workspace, permissions);
        await _audit.LogAsync("login", "user", user.Id, ct: ct);
        await _db.SaveChangesAsync(ct);

        return BuildResponse(token, user, workspace, permissions);
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        var email = request.Email.ToLowerInvariant().Trim();
        if (_db.Users.Any(u => u.Email == email))
            throw new AppException(ErrorCodes.Conflict, "Email already registered", 409);

        var orgSlug = Slugify(request.OrganizationName);
        var workspaceSlug = Slugify(request.WorkspaceName);

        var org = Organization.Create(request.OrganizationName, orgSlug);
        var workspace = Workspace.Create(org.Id, request.WorkspaceName, workspaceSlug);
        var brand = Brand.Create(workspace.Id, request.OrganizationName, isDefault: true);

        var adminRole = Role.CreateSystemRole("Admin", Permissions.All);
        var user = User.Create(email, BCrypt.Net.BCrypt.HashPassword(request.Password), request.FirstName, request.LastName);
        var membership = WorkspaceMembership.Create(workspace.Id, user.Id, adminRole.Id);

        _db.Organizations.Add(org);
        _db.Workspaces.Add(workspace);
        _db.Brands.Add(brand);
        _db.Roles.Add(adminRole);
        _db.Users.Add(user);
        _db.WorkspaceMemberships.Add(membership);

        var token = GenerateToken(user, workspace, adminRole.Permissions.ToList());
        await _audit.LogAsync("create", "user", user.Id, newValues: new { user.Email }, ct: ct);
        await _db.SaveChangesAsync(ct);

        return BuildResponse(token, user, workspace, adminRole.Permissions.ToList());
    }

    public Task<UserProfileDto> GetProfileAsync(CancellationToken ct = default)
    {
        if (!_tenant.UserId.HasValue)
            throw new AppException(ErrorCodes.Unauthorized, "Not authenticated", 401);

        var user = _db.Users.Find(_tenant.UserId.Value)
            ?? throw new AppException(ErrorCodes.NotFound, "User not found", 404);

        return Task.FromResult(new UserProfileDto(user.Id, user.Email, user.FirstName, user.LastName, user.FullName));
    }

    private string GenerateToken(User user, Workspace workspace, IReadOnlyList<string> permissions)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _config["Jwt:Secret"] ?? "pulse-dev-secret-key-min-32-chars-long!!"));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddHours(int.Parse(_config["Jwt:ExpiryHours"] ?? "24"));

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new("workspace_id", workspace.Id.ToString()),
            new("org_id", workspace.OrganizationId.ToString())
        };
        claims.AddRange(permissions.Select(p => new Claim("permission", p)));

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"] ?? "pulse",
            audience: _config["Jwt:Audience"] ?? "pulse-api",
            claims: claims,
            expires: expires,
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static AuthResponse BuildResponse(string token, User user, Workspace workspace, IReadOnlyList<string> permissions) =>
        new(token, "Bearer", 86400,
            new UserProfileDto(user.Id, user.Email, user.FirstName, user.LastName, user.FullName),
            new WorkspaceSummaryDto(workspace.Id, workspace.OrganizationId, workspace.Name, workspace.Slug, permissions));

    private static string Slugify(string input) =>
        new string(input.ToLowerInvariant()
            .Select(c => char.IsLetterOrDigit(c) ? c : '-')
            .ToArray())
            .Trim('-')
            .Replace("--", "-");
}
