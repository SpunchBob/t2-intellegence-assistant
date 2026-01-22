namespace t2Core.DTOs
{
    public class ProductsResponseDto
    {
        public List<ProductDTO> Products { get; set; } = new List<ProductDTO>();
        public string BestCategory { get; set; } = string.Empty;
        public int Sale { get; set;  } = 10; 
    }
}