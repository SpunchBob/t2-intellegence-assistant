using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class Pet
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }  // FK к User
        public string? Type { get; set; }
        public string? Location { get; set; }
        public string? Crown { get; set; }

        public User User { get; set; } = null!;
    }
}
