namespace Pulse.Domain.Tenants;

public class User : Entity
{
    public string Email { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public string FirstName { get; private set; } = string.Empty;
    public string LastName { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;
    public bool MfaEnabled { get; private set; }
    public DateTimeOffset? LastLoginAt { get; private set; }

    private User() { }

    public static User Create(string email, string passwordHash, string firstName, string lastName)
    {
        return new User
        {
            Email = email.ToLowerInvariant(),
            PasswordHash = passwordHash,
            FirstName = firstName,
            LastName = lastName
        };
    }

    public string FullName => $"{FirstName} {LastName}".Trim();

    public void RecordLogin() => LastLoginAt = DateTimeOffset.UtcNow;
}

public class WorkspaceMembership : Entity
{
    public Guid WorkspaceId { get; private set; }
    public Guid UserId { get; private set; }
    public Guid RoleId { get; private set; }
    public bool IsActive { get; private set; } = true;

    private WorkspaceMembership() { }

    public static WorkspaceMembership Create(Guid workspaceId, Guid userId, Guid roleId)
    {
        return new WorkspaceMembership
        {
            WorkspaceId = workspaceId,
            UserId = userId,
            RoleId = roleId
        };
    }
}

public class Role : Entity
{
    public Guid? WorkspaceId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public bool IsSystemRole { get; private set; }
    public IReadOnlyList<string> Permissions => PermissionsInternal.AsReadOnly();

    public List<string> PermissionsInternal { get; private set; } = [];

    private Role() { }

    public static Role CreateSystemRole(string name, IEnumerable<string> permissions)
    {
        var role = new Role { Name = name, IsSystemRole = true };
        role.PermissionsInternal.AddRange(permissions);
        return role;
    }

    public static Role CreateWorkspaceRole(Guid workspaceId, string name, IEnumerable<string> permissions)
    {
        var role = new Role { WorkspaceId = workspaceId, Name = name };
        role.PermissionsInternal.AddRange(permissions);
        return role;
    }
}

public static class Permissions
{
    public const string ContactsRead = "contacts:read";
    public const string ContactsWrite = "contacts:write";
    public const string ContactsDelete = "contacts:delete";
    public const string ContactsExport = "contacts:export";
    public const string CampaignsRead = "campaigns:read";
    public const string CampaignsWrite = "campaigns:write";
    public const string CampaignsSend = "campaigns:send";
    public const string AutomationsRead = "automations:read";
    public const string AutomationsWrite = "automations:write";
    public const string ReportsRead = "reports:read";
    public const string ReportsExport = "reports:export";
    public const string SettingsRead = "settings:read";
    public const string SettingsWrite = "settings:write";
    public const string UsersManage = "users:manage";
    public const string ApiKeysManage = "api_keys:manage";
    public const string AuditRead = "audit:read";
    public const string BillingRead = "billing:read";
    public const string BillingManage = "billing:manage";
    public const string AdminAll = "admin:*";

    public static readonly string[] All =
    [
        ContactsRead, ContactsWrite, ContactsDelete, ContactsExport,
        CampaignsRead, CampaignsWrite, CampaignsSend,
        AutomationsRead, AutomationsWrite,
        ReportsRead, ReportsExport,
        SettingsRead, SettingsWrite,
        UsersManage, ApiKeysManage, AuditRead,
        BillingRead, BillingManage, AdminAll
    ];
}

public class ApiKey : AuditableEntity
{
    public string Name { get; private set; } = string.Empty;
    public string KeyPrefix { get; private set; } = string.Empty;
    public string KeyHash { get; private set; } = string.Empty;
    public IReadOnlyList<string> Scopes => ScopesInternal.AsReadOnly();
    public DateTimeOffset? ExpiresAt { get; private set; }
    public DateTimeOffset? LastUsedAt { get; private set; }
    public bool IsActive { get; private set; } = true;

    public List<string> ScopesInternal { get; private set; } = [];

    private ApiKey() { }

    public static (ApiKey Key, string PlainTextKey) Create(
        Guid workspaceId,
        string name,
        IEnumerable<string> scopes,
        Guid createdByUserId,
        DateTimeOffset? expiresAt = null)
    {
        var plainKey = $"pulse_{Guid.NewGuid():N}{Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(16)).ToLowerInvariant()}";
        var key = new ApiKey
        {
            WorkspaceId = workspaceId,
            Name = name,
            KeyPrefix = plainKey[..12],
            KeyHash = BCrypt.Net.BCrypt.HashPassword(plainKey),
            ExpiresAt = expiresAt
        };
        key.ScopesInternal.AddRange(scopes);
        key.SetCreatedBy(createdByUserId);
        return (key, plainKey);
    }

    public bool Verify(string plainKey) => BCrypt.Net.BCrypt.Verify(plainKey, KeyHash);

    public void RecordUsage() => LastUsedAt = DateTimeOffset.UtcNow;

    public void Revoke() => IsActive = false;
}
