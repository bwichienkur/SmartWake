using Microsoft.EntityFrameworkCore;
using SmsPlatform.Infrastructure;
using SmsPlatform.Infrastructure.Messaging;
using SmsPlatform.Infrastructure.Persistence;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddHostedService<ScheduledMessageWorker>();

var host = builder.Build();
host.Run();

public class ScheduledMessageWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ScheduledMessageWorker> _logger;

    public ScheduledMessageWorker(IServiceScopeFactory scopeFactory, ILogger<ScheduledMessageWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<SmsDbContext>();
                var queue = scope.ServiceProvider.GetRequiredService<SmsPlatform.Application.Services.IMessageQueue>();

                var due = await db.Messages
                    .Where(m => m.Status == "Scheduled" && m.ScheduledFor <= DateTimeOffset.UtcNow)
                    .Select(m => m.Id)
                    .Take(50)
                    .ToListAsync(stoppingToken);

                foreach (var id in due)
                {
                    var message = await db.Messages.FindAsync([id], stoppingToken);
                    if (message is not null)
                    {
                        message.Status = "Queued";
                        await db.SaveChangesAsync(stoppingToken);
                        await queue.PublishAsync(new SmsPlatform.Application.Services.OutboundMessageJob(id), stoppingToken);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Scheduled message worker error");
            }

            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }
}
