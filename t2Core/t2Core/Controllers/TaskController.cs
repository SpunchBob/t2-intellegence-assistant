using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using t2Core.DTOs;
using t2Core.Models;
using t2Core.Services;


namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TaskController : ControllerBase
    {
        private readonly AppDbContext _db;

        public TaskController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet("getTasks/{userId}")]
        public async Task<ActionResult<List<TaskDTO>>> GetIncompleteTasks(int userId, CancellationToken ct = default)
        {
            try
            {
                if (userId < 1)
                    return BadRequest("Valid positive userId required");

                var userResult = await UserExistence.EnsureUserExistsAsync(userId, _db);
                if (!userResult.Success)
                    return StatusCode(500, userResult.ErrorMessage ?? "Failed to initialize user");

                var completedTaskIds = await _db.UserTasks
                    .Where(ut => ut.UserId == userId && ut.IsCompleted)
                    .Select(ut => ut.TaskId)
                    .ToListAsync(ct);

                var tasks = await _db.PaidTasks
                    .AsNoTracking()
                    .Where(t => !completedTaskIds.Contains(t.Id))  // ← главное исправление
                    .Select(t => new TaskDTO
                    {
                        Id = t.Id,
                        Name = t.Name,
                        Description = t.Description,
                        Reward = t.Reward,
                        IsCompleted = false
                    })
                    .ToListAsync(ct);

                return Ok(tasks);
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

        [HttpPost("complete")]
        public async Task<IActionResult> CompleteTask([FromBody] CompleteTaskDTO dto, CancellationToken ct = default)
        {
            if (dto == null || dto.UserId <= 0 || dto.TaskId <= 0)
                return BadRequest("Invalid user or task id");

            var result = await UserExistence.EnsureUserExistsAsync(dto.UserId, _db);
            if (!result.Success)
                return StatusCode(500, result.ErrorMessage ?? "Failed to initialize user");

            var paidTask = await _db.PaidTasks
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == dto.TaskId, ct);

            if (paidTask == null)
                return NotFound("Task not found");

            var userTask = await _db.UserTasks
                .FirstOrDefaultAsync(ut => ut.UserId == dto.UserId && ut.TaskId == dto.TaskId, ct);

            if (userTask == null)
            {
                userTask = new UserTask
                {
                    UserId = dto.UserId,
                    TaskId = dto.TaskId,
                    IsCompleted = false
                };
                _db.UserTasks.Add(userTask);
            }

            if (userTask.IsCompleted)
                return BadRequest("Task already completed");

            userTask.IsCompleted = true;

            var balance = await _db.Balances
                .FirstAsync(b => b.UserId == dto.UserId, ct);

            balance.Amount += paidTask.Reward;

            await _db.SaveChangesAsync(ct);

            return Ok();
        }
    }
}
