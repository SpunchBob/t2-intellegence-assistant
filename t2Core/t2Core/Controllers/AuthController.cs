using Microsoft.AspNetCore.Mvc;
using t2Core.DTOs;
using Microsoft.EntityFrameworkCore; 
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
        public async Task<ActionResult<LoginResponseDTO>> Login([FromBody] UserCreateDTO dto, CancellationToken ct = default)
        {
            if (dto == null || dto.Id <= 0)
                return BadRequest("Valid positive UserId required");

            try
            {
                var user = await _db.Users.FindAsync(new object[] { dto.Id }, cancellationToken: ct);

                bool isNew = user == null;

                if (isNew)
                {
                    user = new User { UserId = dto.Id };
                    _db.Users.Add(user);
                    _db.Balances.Add(new Balance { UserId = dto.Id, Amount = 0m });
                    await _db.SaveChangesAsync(ct);
                }

                return Ok(new LoginResponseDTO
                {
                    UserId = dto.Id,
                    isNewUser = isNew,
                    Message = isNew ? "User created" : "User already exists"
                });
            }
            catch (DbUpdateException)   // уникальный ключ, конфликт
            {
                return Conflict("User creation conflict");
            }
            catch (Exception)           
            {
                return StatusCode(500);
            }
        }
    }
}
