using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class User
    {
        [Key]
        public int UserId { get; set; }

        public Balance? Balance { get; set; }

        public Pet? Pet { get; set; }

        public ICollection<UserTask> UserTasks { get; set; } = new List<UserTask>();
        public ICollection<Purchase> Purchases { get; set; } = new List<Purchase>();
    }
}
