namespace t2Core.DTOs
{
    public class TaskDTO
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Reward { get; set; }
        public bool IsCompleted { get; set; }
    }
}
