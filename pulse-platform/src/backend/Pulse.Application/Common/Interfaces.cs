namespace Pulse.Application.Common;

public interface ITenantContext
{
    Guid WorkspaceId { get; }
    Guid? UserId { get; }
    Guid? ApiKeyId { get; }
    IReadOnlyList<string> Permissions { get; }
    bool HasPermission(string permission);
}

public class TenantContext : ITenantContext
{
    public Guid WorkspaceId { get; init; }
    public Guid? UserId { get; init; }
    public Guid? ApiKeyId { get; init; }
    public IReadOnlyList<string> Permissions { get; init; } = [];

    public bool HasPermission(string permission) =>
        Permissions.Contains(PermissionConstants.AdminAll) ||
        Permissions.Contains(permission);
}

public static class PermissionConstants
{
    public const string AdminAll = "admin:*";
}

public class PagedResult<T>
{
    public IReadOnlyList<T> Items { get; init; } = [];
    public string? NextCursor { get; init; }
    public bool HasMore { get; init; }
    public int? TotalCount { get; init; }
}

public class CursorPagination
{
    public string? After { get; init; }
    public int Limit { get; init; } = 50;

    public int EffectiveLimit => Math.Clamp(Limit, 1, 200);
}

public class AppException : Exception
{
    public string Code { get; }
    public int StatusCode { get; }

    public AppException(string code, string message, int statusCode = 400)
        : base(message)
    {
        Code = code;
        StatusCode = statusCode;
    }
}

public static class ErrorCodes
{
    public const string NotFound = "NOT_FOUND";
    public const string Unauthorized = "UNAUTHORIZED";
    public const string Forbidden = "FORBIDDEN";
    public const string Validation = "VALIDATION_ERROR";
    public const string Conflict = "CONFLICT";
    public const string RateLimited = "RATE_LIMITED";
    public const string TenantMismatch = "TENANT_MISMATCH";
}
