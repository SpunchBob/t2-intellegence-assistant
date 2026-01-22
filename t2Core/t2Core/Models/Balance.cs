using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class Balance
    {
        [Key]
        public int BalanceId { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }  // Use decimal for currency precision

        public User User { get; set; } = null!;  // Navigation
    }
}
