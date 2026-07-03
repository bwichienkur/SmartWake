using Pulse.Domain.Contacts;
using Pulse.Domain.Tenants;

namespace Pulse.Domain.Tests;

public class ContactTests
{
    [Fact]
    public void Create_SetsEmailLowercase()
    {
        var contact = Contact.Create(Guid.NewGuid(), "Alice@Example.COM", "Alice", "Smith");
        Assert.Equal("alice@example.com", contact.Email);
    }

    [Fact]
    public void DisplayName_UsesNameWhenAvailable()
    {
        var contact = Contact.Create(Guid.NewGuid(), "bob@test.com", "Bob", "Jones");
        Assert.Equal("Bob Jones", contact.DisplayName);
    }

    [Fact]
    public void DisplayName_FallsBackToEmail()
    {
        var contact = Contact.Create(Guid.NewGuid(), "solo@test.com");
        Assert.Equal("solo@test.com", contact.DisplayName);
    }

    [Fact]
    public void RecordEngagement_IncrementsScore()
    {
        var contact = Contact.Create(Guid.NewGuid(), "test@test.com");
        contact.RecordEngagement("email.opened", DateTimeOffset.UtcNow);
        Assert.Equal(1, contact.EngagementScore);
        Assert.NotNull(contact.LastEmailOpenedAt);
    }

    [Fact]
    public void SoftDelete_SetsDeletedFlag()
    {
        var contact = Contact.Create(Guid.NewGuid(), "test@test.com");
        contact.SoftDelete();
        Assert.True(contact.IsDeleted);
        Assert.NotNull(contact.DeletedAt);
    }
}

public class PermissionsTests
{
    [Fact]
    public void All_ContainsCorePermissions()
    {
        Assert.Contains(Permissions.ContactsRead, Permissions.All);
        Assert.Contains(Permissions.CampaignsSend, Permissions.All);
        Assert.Contains(Permissions.ReportsRead, Permissions.All);
        Assert.Contains(Permissions.AdminAll, Permissions.All);
    }
}

public class OrganizationTests
{
    [Fact]
    public void Create_SlugifiesName()
    {
        var org = Organization.Create("Acme Corp", "Acme-Corp");
        Assert.Equal("acme-corp", org.Slug);
    }
}
