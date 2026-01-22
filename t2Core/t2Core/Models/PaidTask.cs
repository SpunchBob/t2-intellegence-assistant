using System.ComponentModel.DataAnnotations;

namespace t2Core.Models
{
    public class PaidTask
    {
        [Key]                      // ← это обязательно
        public int Id { get; set; } // ← или public int PaidTaskId { get; set; }

        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Reward { get; set; }        
        public ICollection<UserTask> UserTasks { get; set; } = new List<UserTask>();
    }
}
