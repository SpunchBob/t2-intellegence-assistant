using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using t2Core.DTOs;
using t2Core.Models;
using t2Core.Services;

namespace t2Core.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseController : ControllerBase
    {
        private readonly AppDbContext _db;

        public PurchaseController(AppDbContext db)
        {
            _db = db;
        }

        // Post: gets json from frontend and add to DB new data
        [HttpPost("makePurchase")]
        public async Task<ActionResult> MakePurchase([FromBody] PurchaseDTO dto, CancellationToken ct = default)
        {
            try
            {
                if (dto == null)
                    return BadRequest("Data is required");

                // Validation
                if (dto.UserId <= 0)
                    return BadRequest("Invalid UserId");

                if (dto.ProductId <= 0)
                    return BadRequest("Invalid ProductId");

                if (dto.PurchasePrice < 0)
                    return BadRequest("Purchase price cannot be negative");

                var user = await UserExistence.EnsureUserExistsAsync(dto.UserId, _db);
                if (!user.Success)
                    return StatusCode(500, user.ErrorMessage ?? "Failed to initialize user");

                // Находим продукт (чтобы убедиться, что он существует)
                var product = await _db.Products
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.ProductId == dto.ProductId, ct);

                if (product == null)
                    return NotFound("Product not found");

                var balance = await _db.Balances.FirstOrDefaultAsync(b => b.UserId == dto.UserId);
                if (balance == null)
                    return NotFound("Balance not found");

                var purchase = new Purchase {
                    UserId = dto.UserId,
                    ProductId = dto.ProductId,
                    PurchasePrice = dto.PurchasePrice,          // фиксируем цену на момент покупки
                    PurchasedAt = dto.PurchasedAt != default
                        ? dto.PurchasedAt
                        : DateTime.UtcNow
                };
                _db.Purchases.Add(purchase);

                // Updating balance
                if (dto.PurchasePrice > balance.Amount) {
                    return BadRequest("Price is bigger then balance!");
                }

                balance.Amount -= dto.PurchasePrice;

                await _db.SaveChangesAsync(ct);

                return Ok(new
                {
                    Message = "Purchase successful",
                    NewBalance = balance.Amount,
                    PurchaseId = purchase.Id
                });
            }
            catch (DbUpdateException dbEx)
            {
                return StatusCode(409, $"Database conflict during purchase: {dbEx}");
            }
            catch (OperationCanceledException)
            {
                return StatusCode(408, "Request cancelled");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Failed to process purchase: {ex}");
            }
        }
    }
}
