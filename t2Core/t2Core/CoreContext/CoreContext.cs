using t2Core.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Reflection.Emit;
using t2Core.Models;

namespace t2Core;

public class AppDbContext : DbContext
{
    public DbSet<User> Users { get; set; }
    public DbSet<Balance> Balances { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<PaidTask> PaidTasks { get; set; }
    public DbSet<UserTask> UserTasks { get; set; }

    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {

        modelBuilder.Entity<PaidTask>()
        .HasKey(t => t.Id);                     // ← явно говорим, что Id — это PK

        modelBuilder.Entity<User>()
            .HasKey(u => u.UserId);

        modelBuilder.Entity<Balance>()
            .HasKey(b => b.BalanceId);

        modelBuilder.Entity<Product>()
            .HasKey(p => p.ProductId);

        modelBuilder.Entity<UserTask>()
            .HasKey(ut => ut.UserTaskId);

        // Relations
        modelBuilder.Entity<Balance>()
            .HasOne(b => b.User)
            .WithOne()  // If one-to-one with User, else WithMany
            .HasForeignKey<Balance>(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // User → UserTask (много)
        modelBuilder.Entity<UserTask>()
            .HasOne(ut => ut.User)
            .WithMany()                        // или .WithMany(u => u.UserTasks) если добавишь коллекцию
            .HasForeignKey(ut => ut.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // PaidTask → UserTask (много)
        modelBuilder.Entity<UserTask>()
            .HasOne(ut => ut.PaidTask)
            .WithMany()                        // или .WithMany(t => t.UserTasks)
            .HasForeignKey(ut => ut.TaskId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}