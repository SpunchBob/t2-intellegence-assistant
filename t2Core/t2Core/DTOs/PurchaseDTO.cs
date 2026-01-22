using System.ComponentModel.DataAnnotations;

namespace t2Core.DTOs
{
    public class PurchaseDTO
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public decimal PurchasePrice { get; set; }
        public DateTime PurchasedAt { get; set; }
    }
}
