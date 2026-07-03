namespace Pulse.Domain.Audit;

public class AuditLog : Entity
{
    public Guid WorkspaceId { get; set; }
    public Guid? UserId { get; set; }
    public Guid? ApiKeyId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public Guid? EntityId { get; set; }
    public string? OldValuesJson { get; set; }
    public string? NewValuesJson { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? TraceId { get; set; }
}

public static class AuditActions
{
    public const string Create = "create";
    public const string Update = "update";
    public const string Delete = "delete";
    public const string Login = "login";
    public const string Export = "export";
    public const string Impersonate = "impersonate";
    public const string Send = "send";
    public const string Approve = "approve";
}
