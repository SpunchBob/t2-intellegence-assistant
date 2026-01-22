namespace t2Core.DTOs
{
    public class LoginResponseDTO
    {
        public int UserId { get; set; }
        public bool? isNewUser { get; set; }
        public string? Message { get; set; }
    }
}
