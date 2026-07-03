namespace Pulse.Application.Auth.Dtos;

public record LoginRequest(string Email, string Password);

public record RegisterRequest(
    string Email,
    string Password,
    string FirstName,
    string LastName,
    string OrganizationName,
    string WorkspaceName);

public record AuthResponse(
    string AccessToken,
    string TokenType,
    int ExpiresIn,
    UserProfileDto User,
    WorkspaceSummaryDto Workspace);

public record UserProfileDto(
    Guid Id,
    string Email,
    string FirstName,
    string LastName,
    string FullName);

public record WorkspaceSummaryDto(
    Guid Id,
    Guid OrganizationId,
    string Name,
    string Slug,
    IReadOnlyList<string> Permissions);
