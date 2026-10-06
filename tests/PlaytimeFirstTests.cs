using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using PlayerActivities.Models;
using PlayerActivities.Models.Enumerations;
using Playnite.SDK.Models;

namespace PlayerActivities.Tests
{
    [TestFixture]
    public class PlaytimeFirstTests
    {
        [Test]
        public void HasFirst_WhenEmpty_ReturnsFalse()
        {
            var data = new PlayerActivitiesData { Items = new List<Activity>() };
            Assert.IsFalse(data.HasFirst(), "HasFirst should return false when no PlaytimeFirst item exists.");
        }

        [Test]
        public void HasFirst_WhenPlaytimeFirstExists_ReturnsTrue()
        {
            var data = new PlayerActivitiesData
            {
                Items = new List<Activity>
                {
                    new Activity { Type = ActivityType.PlaytimeFirst, DateActivity = DateTime.UtcNow.AddDays(-1) }
                }
            };
            Assert.IsTrue(data.HasFirst(), "HasFirst should return true when a PlaytimeFirst item is present.");
        }

        [Test]
        public void FirstLaunch_ShouldAddPlaytimeFirst_ExactlyOnce()
        {
            var data = new PlayerActivitiesData { Items = new List<Activity>() };
            var game = new Game { PlayCount = 0 };

            // Simulate OnGameStarted for the very first time
            if (game.PlayCount <= 1 && !data.HasFirst())
            {
                data.Items.Add(new Activity { Type = ActivityType.PlaytimeFirst });
            }

            Assert.AreEqual(1, data.Items.Count(x => x.Type == ActivityType.PlaytimeFirst));
            Assert.IsTrue(data.HasFirst());

            // Simulate 2nd game launch (PlayCount incremented or same)
            game.PlayCount = 1;
            if (game.PlayCount <= 1 && !data.HasFirst())
            {
                data.Items.Add(new Activity { Type = ActivityType.PlaytimeFirst });
            }

            // Must still be exactly 1!
            Assert.AreEqual(1, data.Items.Count(x => x.Type == ActivityType.PlaytimeFirst),
                "Subsequent launch must not add duplicate PlaytimeFirst activities!");

            // Simulate 3rd game launch (PlayCount = 2)
            game.PlayCount = 2;
            if (game.PlayCount <= 1 && !data.HasFirst())
            {
                data.Items.Add(new Activity { Type = ActivityType.PlaytimeFirst });
            }

            Assert.AreEqual(1, data.Items.Count(x => x.Type == ActivityType.PlaytimeFirst),
                "Launch when PlayCount > 1 must not add PlaytimeFirst activities!");
        }

        [Test]
        public void ExistingGameWithHistory_MustNotTriggerPlaytimeFirst()
        {
            // Game already played 15 times before installing plugin
            var data = new PlayerActivitiesData { Items = new List<Activity>() };
            var game = new Game { PlayCount = 15 };

            if (game.PlayCount <= 1 && !data.HasFirst())
            {
                data.Items.Add(new Activity { Type = ActivityType.PlaytimeFirst });
            }

            Assert.AreEqual(0, data.Items.Count(x => x.Type == ActivityType.PlaytimeFirst),
                "Games with existing play counts > 1 must not be tagged as played for the first time.");
        }

        [Test]
        public void Deduplication_WhenLegacyDataHasDuplicates_KeepsEarliestOnly()
        {
            // Simulates corrupted legacy data (e.g. The Division 2 with 6 duplicate entries)
            var earliestDate = new DateTime(2026, 5, 30, 15, 39, 26, DateTimeKind.Utc);
            var duplicate1 = new DateTime(2026, 10, 4, 13, 48, 0, DateTimeKind.Utc);
            var duplicate2 = new DateTime(2026, 10, 4, 13, 48, 31, DateTimeKind.Utc);
            var duplicate3 = new DateTime(2026, 10, 4, 13, 49, 7, DateTimeKind.Utc);

            var items = new List<Activity>
            {
                new Activity { Type = ActivityType.PlaytimeFirst, DateActivity = duplicate1 },
                new Activity { Type = ActivityType.PlaytimeFirst, DateActivity = earliestDate },
                new Activity { Type = ActivityType.PlaytimeGoal, Value = 25 },
                new Activity { Type = ActivityType.PlaytimeFirst, DateActivity = duplicate2 },
                new Activity { Type = ActivityType.PlaytimeFirst, DateActivity = duplicate3 },
            };

            var firstPlaytimes = items.Where(y => y.Type == ActivityType.PlaytimeFirst).OrderBy(y => y.DateActivity).ToList();
            if (firstPlaytimes.Count > 1)
            {
                items.RemoveAll(y => y.Type == ActivityType.PlaytimeFirst);
                items.Add(firstPlaytimes[0]);
            }

            Assert.AreEqual(1, items.Count(x => x.Type == ActivityType.PlaytimeFirst),
                "Deduplication must reduce PlaytimeFirst entries to exactly 1.");
            Assert.AreEqual(earliestDate, items.First(x => x.Type == ActivityType.PlaytimeFirst).DateActivity,
                "Deduplication must preserve the earliest first-played timestamp.");
        }
    }
}
