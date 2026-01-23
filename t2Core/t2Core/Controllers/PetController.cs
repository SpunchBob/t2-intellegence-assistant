using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using t2Core.DTOs;
using t2Core.Models;
using t2Core.Services;

namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PetController : ControllerBase
    {
        private readonly AppDbContext _db;

        public PetController(AppDbContext db)
        {
            _db = db;
        }

        // GET: Получить информацию о питомце пользователя
        [HttpGet("getPet/{userId}")]
        public async Task<ActionResult<PetDTO>> GetPet(int userId, CancellationToken ct = default)
        {
            try
            {
                if (userId < 1)
                    return BadRequest("Invalid user id");

                var userResult = await UserExistence.EnsureUserExistsAsync(userId, _db);
                if (!userResult.Success)
                    return StatusCode(500, userResult.ErrorMessage ?? "Failed to initialize user");

                var user = await _db.Users
                    .Include(u => u.Pet)  // Загружаем питомца
                    .FirstOrDefaultAsync(u => u.UserId == userId, ct);

                if (user == null)
                    return NotFound("User not found");

                if (user.Pet == null)
                    return Ok(new PetDTO());  // Пустой DTO, если питомца нет

                return Ok(new PetDTO
                {
                    Id = user.Pet.Id,
                    Type = user.Pet.Type,
                    Location = user.Pet.Location ?? null,  // null если нет
                    Crown = user.Pet.Crown ?? null        // null если нет
                });
            }
            catch (InvalidOperationException)
            {
                // Ошибка при запросе к БД (например, несколько балансов)
                return StatusCode(500, "Data inconsistency error");
            }
            catch (OperationCanceledException)
            {
                // Таймаут или отмена запроса
                return StatusCode(408, "Request timeout");
            }
            catch (Exception ex)
            {
                // Любые другие непредвиденные ошибки
                return StatusCode(500, $"Internal server error {ex.Message}");
            }
        }

        // PUT: Обновить / создать питомца
        [HttpPut("updatePet/{userId}")]
        public async Task<ActionResult> UpdatePet(int userId, [FromBody] PetDTO dto, CancellationToken ct = default)
        {
            if (dto == null)
                return BadRequest("Pet data is required");

            if (userId < 1)
                return BadRequest("Invalid user id");

            var userResult = await UserExistence.EnsureUserExistsAsync(userId, _db);
            if (!userResult.Success)
                return StatusCode(500, userResult.ErrorMessage ?? "Failed to initialize user");

            try
            {
                var user = await _db.Users
                    .Include(u => u.Pet)
                    .FirstOrDefaultAsync(u => u.UserId == userId, ct);

                if (user == null)
                    return NotFound("User not found");

                // Если питомца нет — создаём нового
                if (user.Pet == null)
                {
                    user.Pet = new Pet { UserId = userId };
                }

                // Обновляем только если прислали (если пусто — не трогаем)
                if (!string.IsNullOrEmpty(dto.Type))
                    user.Pet.Type = dto.Type;

                if (dto.Location != null)
                    user.Pet.Location = dto.Location;

                if (dto.Crown != null)
                    user.Pet.Crown = dto.Crown;

                await _db.SaveChangesAsync(ct);

                return Ok("Pet updated successfully");
            }
            catch (DbUpdateException)
            {
                return Conflict("Database conflict during update");
            }
            catch (Exception)
            {
                return StatusCode(500);
            }
        }
    }
}