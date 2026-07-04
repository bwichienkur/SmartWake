using MassTransit;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SmsPlatform.Application.Interfaces;
using SmsPlatform.Application.Services;

namespace SmsPlatform.Infrastructure.Messaging;

public class MassTransitMessageQueue : IMessageQueue
{
    private readonly IPublishEndpoint _publish;

    public MassTransitMessageQueue(IPublishEndpoint publish) => _publish = publish;

    public Task PublishAsync(OutboundMessageJob job, CancellationToken cancellationToken = default) =>
        _publish.Publish(job, cancellationToken);
}

public class InProcessMessageQueue : IMessageQueue
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<InProcessMessageQueue> _logger;

    public InProcessMessageQueue(IServiceScopeFactory scopeFactory, ILogger<InProcessMessageQueue> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public Task PublishAsync(OutboundMessageJob job, CancellationToken cancellationToken = default)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var service = scope.ServiceProvider.GetRequiredService<IMessageService>();
                await service.ProcessOutboundAsync(job.MessageId, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "In-process message processing failed for {MessageId}", job.MessageId);
            }
        }, cancellationToken);

        return Task.CompletedTask;
    }
}

public class OutboundMessageConsumer : IConsumer<OutboundMessageJob>
{
    private readonly IMessageService _messages;
    private readonly ILogger<OutboundMessageConsumer> _logger;

    public OutboundMessageConsumer(IMessageService messages, ILogger<OutboundMessageConsumer> logger)
    {
        _messages = messages;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OutboundMessageJob> context)
    {
        try
        {
            await _messages.ProcessOutboundAsync(context.Message.MessageId, context.CancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed processing outbound message {MessageId}", context.Message.MessageId);
            throw;
        }
    }
}
