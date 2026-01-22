using Microsoft.AspNetCore.Mvc;
using t2Core.DTOs;
using t2Core.Services;
using Microsoft.EntityFrameworkCore;

namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BalanceController : ControllerBase
    {
        private readonly AppDbContext _db;

        public BalanceController(AppDbContext db)
        {
            _db = db;
        }

        // GET: Получить баланс по userId
        [HttpGet("{userId}")]
        public async Task<ActionResult<BalanceDTO>> GetBalance(int userId, CancellationToken ct = default)
        {
            try
            {
                var result = await UserExistence.EnsureUserExistsAsync(userId, _db);
                if (!result.Success)
                    return StatusCode(500, "Failed to initialize user");

                var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId, ct);

                return Ok(new BalanceDTO { Amount = balance?.Amount ?? 0 });
            }
            catch(InvalidOperationException)
            {
                // Ошибка при запросе к БД (например, несколько балансов)
                return StatusCode(500, "Data inconsistency error");
            }
            catch (OperationCanceledException)
            {
                // Таймаут или отмена запроса
                return StatusCode(408, "Request timeout");
            }
            catch (Exception)
            {
                // Любые другие непредвиденные ошибки
                return StatusCode(500, "Internal server error");
            }
        }

        // PUT: Обновить баланс (для фронтенда, но осторожно — в реале обновляй через действия)
        [HttpPut("{userId}")]
        public async Task<ActionResult> UpdateBalance(int userId, [FromBody] BalanceDTO request, CancellationToken ct = default)
        {
            try
            {
                if (request == null)
                    return BadRequest("Balance is required!");

                var result = await UserExistence.EnsureUserExistsAsync(userId, _db);
                if (!result.Success)
                    return StatusCode(500, "Failed to initialize user");

                if (request.Amount < 0)
                    return BadRequest($"Balance should be 0 or more");

                var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId);
                if (balance == null) return NotFound("Balance not found");

                balance.Amount = request.Amount;
                await _db.SaveChangesAsync(ct);
                return Ok("Balance updated");
            }
            catch (InvalidOperationException ex)
            {
                // Ошибка при запросе к БД (например, несколько балансов)
                return StatusCode(500, "Data inconsistency error");
            }
            catch (OperationCanceledException)
            {
                // Таймаут или отмена запроса
                return StatusCode(408, "Request timeout");
            }
            catch (Exception)
            {
                // Любые другие непредвиденные ошибки
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
