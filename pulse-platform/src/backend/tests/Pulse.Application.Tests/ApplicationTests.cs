using Pulse.Application.Common;

namespace Pulse.Application.Tests;

public class TenantContextTests
{
    [Fact]
    public void HasPermission_ReturnsTrueForExactMatch()
    {
        var ctx = new TenantContext
        {
            WorkspaceId = Guid.NewGuid(),
            Permissions = ["contacts:read", "campaigns:write"]
        };
        Assert.True(ctx.HasPermission("contacts:read"));
        Assert.False(ctx.HasPermission("contacts:delete"));
    }

    [Fact]
    public void HasPermission_AdminAllGrantsEverything()
    {
        var ctx = new TenantContext
        {
            WorkspaceId = Guid.NewGuid(),
            Permissions = ["admin:*"]
        };
        Assert.True(ctx.HasPermission("anything:here"));
    }
}

public class CursorPaginationTests
{
    [Theory]
    [InlineData(0, 1)]
    [InlineData(50, 50)]
    [InlineData(200, 200)]
    [InlineData(500, 200)]
    public void EffectiveLimit_ClampsBetween1And200(int input, int expected)
    {
        var pagination = new CursorPagination { Limit = input };
        Assert.Equal(expected, pagination.EffectiveLimit);
    }
}

public class AppExceptionTests
{
    [Fact]
    public void Constructor_SetsCodeAndStatus()
    {
        var ex = new AppException(ErrorCodes.NotFound, "Not found", 404);
        Assert.Equal("NOT_FOUND", ex.Code);
        Assert.Equal(404, ex.StatusCode);
        Assert.Equal("Not found", ex.Message);
    }
}
