namespace t2Core.DTOs
{
    public class PetDTO
    {
        public int Id { get; set; }
        public string Type { get; set; } = string.Empty;  // Тип питомца
        public string? Location { get; set; }  // Опционально, null если нет
        public string? Crown { get; set; }  // Опционально, null если нет
    }
}