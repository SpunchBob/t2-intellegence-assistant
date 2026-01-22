using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class Purchase
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ProductId { get; set; }

        [Required]
        public decimal PurchasePrice { get; set; }          
        public DateTime PurchasedAt { get; set; } = DateTime.UtcNow; 

        public User User { get; set; } = null!;
        public Product Product { get; set; } = null!;
    }
}
