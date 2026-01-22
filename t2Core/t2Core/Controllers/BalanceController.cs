using Microsoft.AspNetCore.Mvc;
using t2Core.DTOs;
using t2Core.Models;
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
        public async Task<ActionResult<BalanceDTO>> GetBalance(string userId)
        {
            await EnsureUserExists(userId);
            var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId);
            return Ok(new BalanceDTO { Amount = balance?.Amount ?? 0 });
        }

        // PUT: Обновить баланс (для фронтенда, но осторожно — в реале обновляй через действия)
        [HttpPut("{userId}")]
        public async Task<ActionResult> UpdateBalance(string userId, [FromBody] BalanceDTO request)
        {
            await EnsureUserExists(userId);
            var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == userId);
            if (balance == null) return NotFound("Balance not found");

            balance.Amount = request.Amount;
            await _db.SaveChangesAsync();
            return Ok("Balance updated");
        }

        private async Task EnsureUserExists(string userId)
        {
            var user = await _db.Users.FindAsync(userId);
            if (user == null)
            {
                user = new User { UserId = userId };
                _db.Users.Add(user);
                _db.Balances.Add(new Balance { UserId = userId, Amount = 0 });
                await _db.SaveChangesAsync();
            }
        }
    }
}
