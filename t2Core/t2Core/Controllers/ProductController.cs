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
        public async Task<ActionResult<ProductDTO>> GetProducts(int userId)
        {
            if (userId == null)
                return BadRequest("UserId is required");


            await UserExistence.EnsureUserExistsAsync(userId, _db);  // если нужно создавать пользователя локально

            try {
                var client = _httpClientFactory.CreateClient();
                var requestUrl = $"{_bestCategotyURL}?userId={userId}";  // или POST, если нужно тело

                var response = await client.GetAsync(requestUrl);
                response.EnsureSuccessStatusCode();

                var json = await response.Content.ReadAsStringAsync();
                var externalData = JsonSerializer.Deserialize<BestProductDTO>(json);

                if (externalData == null)
                    return StatusCode(502, "Invalid response from external service");

                // Получаем все продукты из своей базы
                var localProducts = await _db.Products
                    .AsNoTracking()
                    .ToListAsync();

                // Формируем DTO с учётом рекомендации от внешнего сервиса
                var productDtos = localProducts.Select(p => new ProductDTO
                {
                    Id = p.ProductId,
                    Name = p.Name,
                    Description = p.Description,
                    Price = p.Price,
                    Category = "",  // ← пока пусто, т.к. категории нет в модели Product
                    IsDiscounted = p.Name.Contains(externalData.BestCategorytName, StringComparison.OrdinalIgnoreCase)
                                   || p.Description.Contains(externalData.BestCategorytName, StringComparison.OrdinalIgnoreCase),
                    DiscountedPrice = p.Name.Contains(externalData.BestCategorytName, StringComparison.OrdinalIgnoreCase)
                        ? Math.Round(p.Price * 0.9m, 2)
                        : p.Price
                }).ToList();

                // Собираем финальный ответ
                var result = new ProductsResponseDto
                {
                    Products = productDtos,
                    BestCategory = externalData.BestCategorytName,
                    Sale = 10
                };

                return Ok(result);
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
            catch (Exception ex)
            {
                // Логировать
                return StatusCode(500, "Internal error");
            }
        }   
    }
}
