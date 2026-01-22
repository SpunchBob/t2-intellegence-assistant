using Microsoft.AspNetCore.Mvc;
using t2Core.DTOs;
using t2Core.Models;

namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _db;

        public AuthController(AppDbContext db)
        {
            _db = db;
        }

        // POST: "Вход" — создать пользователя если нет, вернуть userId или подтверждение
        [HttpPost("login")]
        public async Task<ActionResult<string>> Login([FromBody] UserCreateDTO request)
        {
            var userId = request.Id;
            if (string.IsNullOrEmpty(userId)) return BadRequest("UserId required");

            var user = await _db.Users.FindAsync(userId);
            if (user == null)
            {
                user = new User { UserId = userId };
                _db.Users.Add(user);
                _db.Balances.Add(new Balance { UserId = userId, Amount = 0 });
                await _db.SaveChangesAsync();
                return Ok($"User created: {userId}");
            }

            return Ok($"User exists: {userId}");
        }
    }
}
