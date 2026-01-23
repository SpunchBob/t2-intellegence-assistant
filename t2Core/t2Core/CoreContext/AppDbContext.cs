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
    public DbSet<Pet> Pets { get; set; }
    public DbSet<Purchase> Purchases { get; set; }

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

        modelBuilder.Entity<Purchase>()
            .HasKey(p => p.Id);

        // Связи

        // 1:1 User ↔ Balance (самый чистый вариант)
        modelBuilder.Entity<Balance>()
            .HasOne(b => b.User)
            .WithOne(u => u.Balance)           // ← добавь в User: public Balance? Balance { get; set; }
            .HasForeignKey<Balance>(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // User → UserTask (1 : много)
        modelBuilder.Entity<UserTask>()
            .HasOne(ut => ut.User)
            .WithMany(u => u.UserTasks)        // ← добавь в User
            .HasForeignKey(ut => ut.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // PaidTask → UserTask (1 : много)
        modelBuilder.Entity<UserTask>()
            .HasOne(ut => ut.PaidTask)
            .WithMany(t => t.UserTasks)        // уже есть
            .HasForeignKey(ut => ut.TaskId)
            .OnDelete(DeleteBehavior.Restrict);

        // User → Purchase (1 : много)
        modelBuilder.Entity<Purchase>()
            .HasOne(p => p.User)
            .WithMany(u => u.Purchases)        // ← добавь в User
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Pet>()
            .HasOne(p => p.User)
            .WithOne(u => u.Pet)
            .HasForeignKey<Pet>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Product → Purchase (1 : много)
        modelBuilder.Entity<Purchase>()
            .HasOne(p => p.Product)
            .WithMany()                        // можно добавить в Product: ICollection<Purchase> Purchases
            .HasForeignKey(p => p.ProductId)
            .OnDelete(DeleteBehavior.Restrict); // продукт не удаляем, если есть покупки

        // ────────────────────────────────────────────────────────────────
        // Индексы (очень важно для скорости)

        modelBuilder.Entity<Balance>()
            .HasIndex(b => b.UserId)
            .IsUnique();   // один пользователь = один баланс

        modelBuilder.Entity<UserTask>()
            .HasIndex(ut => new { ut.UserId, ut.TaskId })
            .IsUnique();   // один пользователь не может иметь две записи по одной задаче

        modelBuilder.Entity<Purchase>()
            .HasIndex(p => p.UserId);
    }
}