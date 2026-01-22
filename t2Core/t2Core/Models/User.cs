using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class User
    {
        [Key]
        public string? UserId { get; set; }
    }
}
