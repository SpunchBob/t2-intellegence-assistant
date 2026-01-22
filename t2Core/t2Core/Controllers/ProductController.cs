using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using t2Core.DTOs;
using t2Core.Services;
using t2Core.Models;

namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string _bestCategotyURL = "https://external-service.example.com/api/products";

        public ProductController(AppDbContext db, IHttpClientFactory httpClientFactory)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
        }

        // GET: Получить все продукты + лучшую категорию продуктов со скидкой 10%
        [HttpGet("getProducts/{userId}")]
        public async Task<ActionResult<ProductsResponseDto>> GetProducts(int userId, CancellationToken ct = default)
        {
            if (userId <= 0)
                return BadRequest("Invalid user id");

            var userResult = await UserExistence.EnsureUserExistsAsync(userId, _db);
            if (!userResult.Success)
                return StatusCode(500, userResult.ErrorMessage ?? "Failed to initialize user");

            try {
                var client = _httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(6);

                var requestUrl = $"{_bestCategotyURL}?userId={userId}";  // или POST, если нужно тело

                var response = await client.GetAsync(requestUrl);
                response.EnsureSuccessStatusCode();

                var json = await response.Content.ReadAsStringAsync();
                var externalData = JsonSerializer.Deserialize<BestProductDTO>(json);

                if (externalData == null)
                    return StatusCode(502, "Invalid response from external service");

                // Получаем все продукты из своей базы
                var products = await _db.Products
                    .AsNoTracking()
                    .ToListAsync(ct);

                // Формируем DTO с учётом рекомендации от внешнего сервиса
                var dtos = products.Select(p => new ProductDTO
                {
                    Id = p.ProductId,
                    Name = p.Name,
                    Description = p.Description,
                    Price = p.Price,
                    Category = p.Category ?? "Без категории",
                    IsDiscounted = p.Category == externalData.BestCategorytName,
                    DiscountedPrice = p.Category == externalData.BestCategorytName
                ? Math.Round(p.Price * 0.9m, 2)
                : p.Price
                }).ToList();

                return Ok(new ProductsResponseDto
                {
                    Products = dtos,
                    BestCategory = externalData.BestCategorytName,
                    Sale = 10
                });
            }
            catch (HttpRequestException ex) when (ex.InnerException is TimeoutException)
            {
                return StatusCode(504, "External service timeout");
            }
            catch (HttpRequestException ex)
            {
                // Логировать в продакшене
                return StatusCode(502, $"External service unavailable: {ex.Message}");
            }
            catch (JsonException)
            {
                return StatusCode(502, "Invalid format from external service");
            }
            catch (Exception)
            {
                // Логировать
                return StatusCode(500, "Internal error");
            }
        }   
    }
}
