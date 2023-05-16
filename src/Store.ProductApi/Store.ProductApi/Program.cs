using Bogus;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var products = new Faker<Product>()
    .StrictMode(true)
    .RuleFor(p => p.ProductId, (f, p) => f.Database.Random.Guid())
    .RuleFor(p => p.ProductName, (f, p) => f.Commerce.ProductName())
    .RuleFor(p => p.Manufacturer, (f, p) => f.Company.CompanyName())
    .Generate(10);

app.MapGet("/products", () => Results.Ok(products))
    .Produces<Product[]>(StatusCodes.Status200OK)
    .WithName("GetProducts");

// Health Check
app.MapHealthChecks("/healthz/liveness", new HealthCheckOptions()
{
    ResultStatusCodes =
    {
        [HealthStatus.Healthy] = StatusCodes.Status200OK,
        [HealthStatus.Degraded] = StatusCodes.Status200OK,
        [HealthStatus.Unhealthy] = StatusCodes.Status500InternalServerError,
    }
});

app.Run();

public class Product
{
    public Guid ProductId => Guid.NewGuid();
    public string ProductName { get; set; }
    public string Manufacturer { get; set; }
}

// Make the implicit Program class public so test projects can access it
public partial class Program { }