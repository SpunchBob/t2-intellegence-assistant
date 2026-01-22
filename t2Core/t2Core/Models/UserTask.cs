using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class UserTask
    {
        [Key]
        public int UserTaskId { get; set; }
        public int UserId { get; set; }
        public int TaskId { get; set; }
        public bool IsCompleted { get; set; }

        public User User { get; set; } = null!;
        public PaidTask PaidTask { get; set; } = null!;
    }
}
