using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmsPlatform.Application.DTOs;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Infrastructure.Persistence;

namespace SmsPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MessagesController : ControllerBase
{
    private readonly IMessageService _messages;

    public MessagesController(IMessageService messages) => _messages = messages;

    [HttpGet]
    public async Task<ActionResult<PaginatedResult<MessageDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? direction = null,
        CancellationToken cancellationToken = default)
    {
        var org = HttpContext.GetOrganization();
        var result = await _messages.ListMessagesAsync(org.Id, page, Math.Min(pageSize, 100), direction, cancellationToken);
        return Ok(result);
    }

    [HttpPost("send")]
    public async Task<ActionResult<SendMessageResponse>> Send([FromBody] SendMessageRequest request, CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        var result = await _messages.QueueOutboundAsync(org.Id, request, cancellationToken);
        return Accepted(result);
    }
}

[ApiController]
[Route("api/[controller]")]
public class ContactsController : ControllerBase
{
    private readonly IContactService _contacts;

    public ContactsController(IContactService contacts) => _contacts = contacts;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ContactDto>>> List(CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        return Ok(await _contacts.ListAsync(org.Id, cancellationToken));
    }

    [HttpPost]
    public async Task<ActionResult<ContactDto>> Create([FromBody] CreateContactRequest request, CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        var contact = await _contacts.CreateAsync(org.Id, request, cancellationToken);
        return Created($"/api/contacts/{contact.Id}", contact);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        await _contacts.DeleteAsync(org.Id, id, cancellationToken);
        return NoContent();
    }
}

[ApiController]
[Route("api/[controller]")]
public class AnalyticsController : ControllerBase
{
    private readonly IMessageService _messages;
    private readonly IComplianceReportService _compliance;
    private readonly ISmsProviderRouter _providers;

    public AnalyticsController(IMessageService messages, IComplianceReportService compliance, ISmsProviderRouter providers)
    {
        _messages = messages;
        _compliance = compliance;
        _providers = providers;
    }

    [HttpGet("stats")]
    public async Task<ActionResult<DashboardStatsDto>> Stats(CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        return Ok(await _messages.GetStatsAsync(org.Id, cancellationToken));
    }

    [HttpGet("compliance")]
    public async Task<ActionResult<ComplianceReportDto>> Compliance(CancellationToken cancellationToken)
    {
        var org = HttpContext.GetOrganization();
        return Ok(await _compliance.GetReportAsync(org.Id, cancellationToken));
    }

    [HttpGet("providers")]
    public async Task<ActionResult<IReadOnlyList<ProviderHealthDto>>> Providers(CancellationToken cancellationToken) =>
        Ok(await _providers.GetHealthAsync(cancellationToken));
}

[ApiController]
[Route("api/ai")]
public class AiController : ControllerBase
{
    private readonly IIntelligenceService _intelligence;

    public AiController(IIntelligenceService intelligence) => _intelligence = intelligence;

    [HttpPost("analyze")]
    public async Task<ActionResult<AnalyzeContentResponse>> Analyze([FromBody] AnalyzeContentRequest request, CancellationToken cancellationToken) =>
        Ok(await _intelligence.AnalyzeContentAsync(request, cancellationToken));
}

[ApiController]
[Route("api/webhooks")]
public class WebhooksController : ControllerBase
{
    private readonly IMessageService _messages;
    private readonly SmsDbContext _db;

    public WebhooksController(IMessageService messages, SmsDbContext db)
    {
        _messages = messages;
        _db = db;
    }

    [HttpPost("twilio/incoming")]
    public async Task<IActionResult> TwilioIncoming(CancellationToken cancellationToken)
    {
        var orgId = await _db.Organizations.OrderBy(o => o.CreatedAt).Select(o => o.Id).FirstAsync(cancellationToken);
        var payload = new InboundWebhookPayload(
            Request.Form["From"].ToString(),
            Request.Form["To"].ToString(),
            Request.Form["Body"].ToString(),
            Request.Form["MessageSid"].ToString(),
            "Twilio");

        await _messages.HandleInboundAsync(orgId, payload, cancellationToken);
        return Content("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response></Response>", "text/xml");
    }

    [HttpPost("twilio/status")]
    public async Task<IActionResult> TwilioStatus(CancellationToken cancellationToken)
    {
        var sid = Request.Form["MessageSid"].ToString();
        var status = Request.Form["MessageStatus"].ToString();
        if (!string.IsNullOrWhiteSpace(sid))
        {
            await _messages.UpdateDeliveryStatusAsync(sid, status, cancellationToken);
        }

        return Ok();
    }
}

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly SmsDbContext _db;
    private readonly ISmsProviderRouter _providers;

    public HealthController(SmsDbContext db, ISmsProviderRouter providers)
    {
        _db = db;
        _providers = providers;
    }

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        var canConnect = await _db.Database.CanConnectAsync(cancellationToken);
        var providers = await _providers.GetHealthAsync(cancellationToken);
        return Ok(new
        {
            status = canConnect ? "healthy" : "degraded",
            database = canConnect,
            providers,
            timestamp = DateTimeOffset.UtcNow
        });
    }
}

public static class HttpContextExtensions
{
    private const string OrganizationKey = "Organization";

    public static Domain.Entities.Organization GetOrganization(this HttpContext context) =>
        context.Items[OrganizationKey] as Domain.Entities.Organization
        ?? throw new UnauthorizedAccessException("Organization not resolved");

    public static void SetOrganization(this HttpContext context, Domain.Entities.Organization organization) =>
        context.Items[OrganizationKey] = organization;
}
