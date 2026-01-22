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
        public async Task<ActionResult<BalanceDTO>> GetBalance(int userId)
        {
            await UserExistence.EnsureUserExistsAsync(userId, _db);

            var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId);

            return Ok(new BalanceDTO { Amount = balance?.Amount ?? 0 });
        }

        // PUT: Обновить баланс (для фронтенда, но осторожно — в реале обновляй через действия)
        [HttpPut("{userId}")]
        public async Task<ActionResult> UpdateBalance(int userId, [FromBody] BalanceDTO request)
        {
            try
            {
                await UserExistence.EnsureUserExistsAsync(userId, _db);

                var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId);
                if (balance == null) return NotFound("Balance not found");

                balance.Amount = request.Amount;
                await _db.SaveChangesAsync();
                return Ok("Balance updated");
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}
