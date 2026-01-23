using Microsoft.EntityFrameworkCore;
using t2Core.Models;

namespace t2Core.Services
{
    public class UserExistenceResult
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }
        public User? User { get; set; }
    }

    public static class UserExistence
    {
        public static async Task<UserExistenceResult> EnsureUserExistsAsync(int userId, AppDbContext db)
        {
            try
            {
                var user = await db.Users.FindAsync(userId);
                if (user == null)
                {
                    user = new User { UserId = userId };
                    db.Users.Add(user);
                    db.Balances.Add(new Balance { UserId = userId, Amount = 0 });
                    await db.SaveChangesAsync();
                }

                return new UserExistenceResult
                {
                    Success = true,
                    User = user
                };
            }
            catch (Exception ex)
            {
                return new UserExistenceResult
                {
                    Success = false,
                    ErrorMessage = ex.Message
                };
            }
        }
    }
}