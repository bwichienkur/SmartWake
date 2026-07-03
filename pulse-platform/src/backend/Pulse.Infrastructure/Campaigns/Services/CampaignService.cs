using Pulse.Application.Campaigns.Dtos;
using Pulse.Application.Common;
using Pulse.Application.Contacts;
using Pulse.Domain.Campaigns;
using Pulse.Domain.Common;
using Pulse.Infrastructure.Persistence;

namespace Pulse.Infrastructure.Campaigns.Services;

public class CampaignService : ICampaignService
{
    private readonly PulseDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IAuditService _audit;
    private readonly IOutboxPublisher _outbox;

    public CampaignService(PulseDbContext db, ITenantContext tenant, IAuditService audit, IOutboxPublisher outbox)
    {
        _db = db;
        _tenant = tenant;
        _audit = audit;
        _outbox = outbox;
    }

    public async Task<CampaignDto> CreateAsync(CreateCampaignRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new AppException(ErrorCodes.Validation, "Name is required");

        var brand = await _db.Brands.FindAsync([request.BrandId], ct);
        if (brand == null || brand.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.Validation, "Invalid brand");

        var campaign = Campaign.Create(_tenant.WorkspaceId, request.BrandId, request.Name);
        campaign.Subject = request.Subject;
        campaign.PreviewText = request.PreviewText;
        campaign.HtmlContent = request.HtmlContent;
        campaign.MjmlContent = request.MjmlContent;

        if (_tenant.UserId.HasValue)
            campaign.SetCreatedBy(_tenant.UserId.Value);

        _db.Campaigns.Add(campaign);
        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.CampaignCreated, new { campaign.Id, campaign.Name }, ct: ct);
        await _audit.LogAsync("create", "campaign", campaign.Id, newValues: campaign, ct: ct);
        await _db.SaveChangesAsync(ct);

        return Map(campaign);
    }

    public async Task<CampaignDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var campaign = await _db.Campaigns.FindAsync([id], ct);
        if (campaign == null || campaign.WorkspaceId != _tenant.WorkspaceId)
            return null;
        return Map(campaign);
    }

    public async Task<PagedResult<CampaignDto>> ListAsync(CampaignListQuery query, CancellationToken ct = default)
    {
        var q = _db.Campaigns.Where(c => c.WorkspaceId == _tenant.WorkspaceId);

        if (!string.IsNullOrWhiteSpace(query.Status) &&
            Enum.TryParse<CampaignStatus>(query.Status, true, out var status))
            q = q.Where(c => c.Status == status);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.ToLower();
            q = q.Where(c => c.Name.ToLower().Contains(search));
        }

        if (!string.IsNullOrWhiteSpace(query.After) && Guid.TryParse(query.After, out var afterId))
            q = q.Where(c => c.Id.CompareTo(afterId) > 0);

        var limit = Math.Clamp(query.Limit, 1, 200);
        var items = q.OrderBy(c => c.Id).Take(limit + 1).ToList();
        var hasMore = items.Count > limit;
        if (hasMore) items = items.Take(limit).ToList();

        return new PagedResult<CampaignDto>
        {
            Items = items.Select(Map).ToList(),
            NextCursor = hasMore ? items[^1].Id.ToString() : null,
            HasMore = hasMore
        };
    }

    public async Task<CampaignDto> UpdateAsync(Guid id, UpdateCampaignRequest request, CancellationToken ct = default)
    {
        var campaign = await _db.Campaigns.FindAsync([id], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        if (campaign.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        if (request.Name != null) campaign.Name = request.Name;
        if (request.Subject != null) campaign.Subject = request.Subject;
        if (request.PreviewText != null) campaign.PreviewText = request.PreviewText;
        if (request.HtmlContent != null) campaign.HtmlContent = request.HtmlContent;
        if (request.MjmlContent != null) campaign.MjmlContent = request.MjmlContent;
        if (request.FromEmail != null) campaign.FromEmail = request.FromEmail;
        if (request.FromName != null) campaign.FromName = request.FromName;
        if (request.SegmentId.HasValue) campaign.SegmentId = request.SegmentId;
        if (request.ListId.HasValue) campaign.ListId = request.ListId;

        if (_tenant.UserId.HasValue) campaign.SetUpdatedBy(_tenant.UserId.Value);

        await _outbox.PublishAsync(_tenant.WorkspaceId, EventTypes.CampaignUpdated, new { campaign.Id }, ct: ct);
        await _audit.LogAsync("update", "campaign", campaign.Id, ct: ct);
        await _db.SaveChangesAsync(ct);

        return Map(campaign);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var campaign = await _db.Campaigns.FindAsync([id], ct)
            ?? throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        if (campaign.WorkspaceId != _tenant.WorkspaceId)
            throw new AppException(ErrorCodes.NotFound, "Campaign not found", 404);

        campaign.Status = CampaignStatus.Archived;
        await _audit.LogAsync("delete", "campaign", campaign.Id, ct: ct);
        await _db.SaveChangesAsync(ct);
    }

    private static CampaignDto Map(Campaign c) => new(
        c.Id, c.BrandId, c.Name, c.Subject, c.PreviewText,
        c.Status.ToString(), c.Type.ToString(),
        c.ScheduledAt, c.SentAt,
        c.TotalRecipients, c.TotalSent, c.TotalDelivered,
        c.TotalOpened, c.TotalClicked, c.TotalBounced, c.TotalRevenue,
        c.CreatedAt, c.UpdatedAt);
}
