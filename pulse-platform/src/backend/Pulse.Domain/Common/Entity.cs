namespace Pulse.Domain.Common;

public abstract class Entity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();
    public DateTimeOffset CreatedAt { get; protected set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; protected set; } = DateTimeOffset.UtcNow;

    protected void Touch() => UpdatedAt = DateTimeOffset.UtcNow;
}

public abstract class TenantEntity : Entity
{
    public Guid WorkspaceId { get; internal set; }

    protected TenantEntity() { }

    protected TenantEntity(Guid workspaceId)
    {
        WorkspaceId = workspaceId;
    }
}

public abstract class AuditableEntity : TenantEntity
{
    public Guid? CreatedByUserId { get; protected set; }
    public Guid? UpdatedByUserId { get; protected set; }

    public void SetCreatedBy(Guid userId)
    {
        CreatedByUserId = userId;
        UpdatedByUserId = userId;
    }

    public void SetUpdatedBy(Guid userId)
    {
        UpdatedByUserId = userId;
        Touch();
    }
}
