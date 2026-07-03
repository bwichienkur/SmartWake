using Pulse.Infrastructure;
using Pulse.Workers;

var builder = Host.CreateApplicationBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? "Host=localhost;Port=5432;Database=pulse;Username=pulse;Password=pulse_dev";

builder.Services.AddPulseInfrastructure(connectionString);
builder.Services.AddHostedService<OutboxRelayWorker>();

var host = builder.Build();
host.Run();
