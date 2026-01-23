namespace t2Core.DTOs
{
    public class ProductDTO
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Category { get; set; } = string.Empty;  
        public bool IsDiscounted { get; set; }  // Флаг скидки
        public decimal DiscountedPrice { get; set; }  // Цена со скидкой, если применимо
    }
}
