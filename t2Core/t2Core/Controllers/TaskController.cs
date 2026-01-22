using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using t2Core.DTOs;
using t2Core.Models;
using t2Core.Services;


namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/{controller}")]
    public class TaskController : Controller
    {
        private readonly AppDbContext _db;

        public TaskController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet("getTasks/{userId}")]
        public async Task<ActionResult<List<TaskDTO>>> GetIncompleteTasks(int userId)
        {
            try
            {
                await UserExistence.EnsureUserExistsAsync(userId, _db);

                var tasks = await _db.PaidTasks
                 .GroupJoin(_db.UserTasks.Where(ut => ut.UserId == userId && !ut.IsCompleted),
                     t => t.Id,
                     ut => ut.TaskId,
                     (t, utGroup) => new { Task = t, UserTask = utGroup.FirstOrDefault() })
                 .Where(joined => joined.UserTask == null || !joined.UserTask.IsCompleted)
                 .Select(joined => new TaskDTO
                 {
                     Id = joined.Task.Id,
                     Name = joined.Task.Name,
                     Description = joined.Task.Description,
                     Reward = joined.Task.Reward,
                     IsCompleted = false
                 })
                 .ToListAsync();

                return Ok(tasks);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("complete")]
        public async Task<IActionResult> CompleteTask([FromBody] CompleteTaskDTO dto)
        {
            try
            {
                await UserExistence.EnsureUserExistsAsync(dto.UserId, _db);

                if (dto.TaskId == null)
                    return NotFound("Task not found");

                var userTask = await _db.UserTasks
                    .FirstOrDefaultAsync(ut => ut.UserId == dto.UserId && ut.TaskId == dto.TaskId);


                var paidTask = await _db.PaidTasks
                    .FirstOrDefaultAsync(t => t.Id == dto.TaskId);

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

                if (userTask.IsCompleted) return BadRequest("Task already completed");

                userTask.IsCompleted = true;
                var balance = await _db.Balances.FirstAsync(b => b.UserId == dto.UserId);
                balance.Amount += paidTask.Reward;
                await _db.SaveChangesAsync();

                return Ok("Task completed, reward added");
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}
