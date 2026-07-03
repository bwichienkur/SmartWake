namespace Pulse.Domain.Tenants;

public class Brand : AuditableEntity
{
    public string Name { get; private set; } = string.Empty;
    public string? FromEmail { get; set; }
    public string? FromName { get; set; }
    public string? ReplyToEmail { get; set; }
    public string? PrimaryColor { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsDefault { get; set; }

    private Brand() { }

    public static Brand Create(Guid workspaceId, string name, bool isDefault = false)
    {
        return new Brand
        {
            WorkspaceId = workspaceId,
            Name = name,
            IsDefault = isDefault
        };
    }
}

public class Organization : Entity
{
    public string Name { get; private set; } = string.Empty;
    public string Slug { get; private set; } = string.Empty;
    public string PlanTier { get; private set; } = "starter";
    public bool IsActive { get; private set; } = true;

    private Organization() { }

    public static Organization Create(string name, string slug, string planTier = "starter")
    {
        return new Organization
        {
            Name = name,
            Slug = slug.ToLowerInvariant(),
            PlanTier = planTier
        };
    }
}

public class Workspace : Entity
{
    public Guid OrganizationId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Slug { get; private set; } = string.Empty;
    public string TimeZone { get; set; } = "UTC";
    public bool IsActive { get; private set; } = true;
    public int DataRetentionDays { get; set; } = 365;
    public bool CrmEnabled { get; set; }

    private Workspace() { }

    public static Workspace Create(Guid organizationId, string name, string slug)
    {
        return new Workspace
        {
            OrganizationId = organizationId,
            Name = name,
            Slug = slug.ToLowerInvariant()
        };
    }
}
