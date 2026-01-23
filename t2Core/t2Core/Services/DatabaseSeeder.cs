using Microsoft.EntityFrameworkCore;
using t2Core.Models;

namespace t2Core.Services
{
    public class DatabaseSeeder
    {
        public static async Task SeedAsync(AppDbContext db, CancellationToken ct = default)
        {
            try {
                // Если таблицы уже заполнены — ничего не делаем
                if (await db.Products.AnyAsync() && await db.PaidTasks.AnyAsync(ct))
                    return;

                // Продукты
                if (!await db.Products.AnyAsync(ct))
                {
                    db.Products.AddRange(
                        new Product
                        {
                            Name = "100 ГБ интернета",
                            Description = "Дополнительный пакет трафика на 30 дней",
                            Category = "gb",
                            Price = 100m
                        },
                        new Product
                        {
                            Name = "300 минут звокнок",
                            Description = "Дополнительный пакет минут на звонки по всей стране",
                            Category = "min",
                            Price = 80m
                        },
                        new Product
                        {
                            Name = "400 сообщений в месяц",
                            Description = "Дополнительный пакет на 400т сообщений в месяц",
                            Category = "msg",
                            Price = 100m
                        }
                    );
                }

                // Задания
                if (!await db.PaidTasks.AnyAsync(ct))
                {
                    db.PaidTasks.AddRange(
                        new PaidTask
                        {
                            Name = "Зайди в приложение 7 дней подряд",
                            Description = "Заходи каждый день в течение недели",
                            Reward = 20m
                        },
                        new PaidTask
                        {
                            Name = "Купи любой товар в магазине",
                            Description = "Соверши хотя бы одну покупку",
                            Reward = 50m
                        },
                        new PaidTask
                        {
                            Name = "Поделись приложением с другом",
                            Description = "Пригласи друга по реферальной ссылке",
                            Reward = 300m
                        }
                    );
                }

                // Тестовый пользователь (если нужно)
                if (!await db.Users.AnyAsync(ct))
                {
                    var testUser = new User { UserId = 1 };
                    db.Users.Add(testUser);
                    db.Balances.Add(new Balance { UserId = 1, Amount = 0m });
                }

                // Добавляем питомца для пользователя 1 (если ещё нет)
                if (!await db.Pets.AnyAsync(p => p.UserId == 1, ct))
                {
                    db.Pets.Add(new Pet
                    {
                        UserId = 1,
                        Type = "dargon",          
                        Location = "home",
                        Crown = "golden"     
                    });
                }

                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException dbEx)
            {
                // Конфликт уникальности / FK / другие ошибки БД — это критично
                // Логируем с уровнем Error или Critical
                Console.WriteLine($"[ERROR] Seed failed due to database conflict: {dbEx.InnerException?.Message ?? dbEx.Message}");
                // или лучше: _logger.LogError(dbEx, "Database seeding failed");
                throw; // ← перевыбрасываем, чтобы приложение упало или обработалось выше
            }
            catch (OperationCanceledException)
            {
                // Отмена токена — нормальная ситуация при shutdown
                Console.WriteLine("[INFO] Seeding cancelled");
                throw; // можно и не бросать, но лучше бросить
            }
            catch (Exception ex)
            {
                // Всё остальное — критично
                Console.WriteLine($"[CRITICAL] Seeding failed: {ex.Message}");
                // _logger.LogCritical(ex, "Unexpected error during database seeding");
                throw; // обязательно перевыбрасываем
            }
        }
    }
}
