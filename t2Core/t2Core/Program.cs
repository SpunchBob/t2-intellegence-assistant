using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;  // ← ключевой using для OpenApiInfo / OpenApiContact
using t2Core;
using t2Core.Services;

var builder = WebApplication.CreateBuilder(args);

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")
    ));

// Контроллеры
builder.Services.AddControllers();
builder.Services.AddHttpClient();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "T2 Intelligence Assistant API",
        Version = "v1",
        Description = "API для приложения-помощника T2 (хакатон)",
        Contact = new OpenApiContact
        {
            Name = "Иван",
            Email = "ivan@example.com"
        }
    });
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

var app = builder.Build();

// Swagger UI
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "T2 API v1");
        c.RoutePrefix = string.Empty;
        c.DocumentTitle = "T2 Intelligence Assistant - Swagger";
    });
}

// Автоматическое применение миграций + сидирование данных
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

    try
    {
        // 1. Применяем все миграции (создаёт БД, если её нет)
        await db.Database.MigrateAsync();

        // 2. Заполняем тестовыми данными (если нужно)
        await DatabaseSeeder.SeedAsync(db);
    }
    catch (Exception ex)
    {
        // Критично — если миграции не применились, приложение не должно запускаться
        Console.WriteLine($"[FATAL] Database migration failed: {ex.Message}");
        // Можно даже Environment.Exit(1); чтобы контейнер упал и логи показали ошибку
        throw;  // или просто throw, чтобы Kestrel показал ошибку в логах
    }
}


app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

app.Run();