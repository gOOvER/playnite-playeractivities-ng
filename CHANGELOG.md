# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.2.0] - 2026-10-07

### Added
- **Modern SDK-Style Project**: Migrated `PlayerActivities.csproj` to modern SDK-style project format (`Microsoft.NET.Sdk`, `net462`, `UseWpf`, `LangVersion 10.0`, `PackageReference`), removing legacy `packages.config`.
- **Submodule Direct Integration**: Integrated `playnite-plugincommon` directly into the repository and removed `.gitmodules` to eliminate git submodule friction.
- **Process Security**: Enforced URI scheme validation (`http`/`https`) and `UseShellExecute` in `ProcessStarter.StartUrl` and `Commands.NavigateUrl` to prevent command injection, with safe shell fallback quoting.

### Changed
- **UI Responsiveness & Async Enhancements**:
  - Replaced UI-thread blocking `SpinWait.SpinUntil` in `OnApplicationStarted` with asynchronous background task migration for legacy friends data.
  - Replaced synchronous `Thread.Sleep(10000)` in `OnGameStopped` with non-blocking `await Task.Delay(10000)`.
  - Removed artificial 5-second `Thread.Sleep(5000)` stall during `InitializePluginData`.
- **Game Selection Performance**: Optimized `GetActivitiesData(Guid id)` by querying and grouping activities specifically for the requested game instead of scanning and aggregating the entire library database on every game selection.

### Fixed
- **Win32 File Handle Leak**: Fixed OS file handle leak in `Paths.GetFinalPathName(path)` where UNC paths returned early without closing the Kernel32 file handle.
- **Settings Null Reference Exception**: Added null checks for `SteamApi`, `EpicApi`, and `GogApi` during settings save in `PlayerActivitiesSettingsViewModel.EndEdit`.
- **StoreApi Null Guard**: Added null-safe navigation in `GenericFriends.BuildPlayerFriend` when retrieving account game data.
- **SteamKit Robustness & Invariant Parsing**: Added null and `KeyValue.Invalid` checks across all SteamKit2 API responses (`GetAppList`, `GetFriendList`, `GetPlayerSummaries`, `GetOwnedGames`, `GetGameAchievements`, `GetSchemaForGame`, `GetUserStatsForGame`, `GetPlayerAchievements`), and parsed achievement percentages with `CultureInfo.InvariantCulture`.
- **Steam Store Details Dictionary Lookup**: Safely accessed app details with `TryGetValue` in `SteamApi.GetAppDetails` to avoid `KeyNotFoundException`.
- **EA App Null Protection**: Added null-conditional operators when enumerating `responseOwnedGameProducts.Data.Me.OwnedGameProducts.Items` in `EaApi`.
- **Web Redirect Loop Protection**: Added maximum redirect depth limit (5 hops) in `Web.DownloadStringData` to prevent stack overflow on circular HTTP redirects.
- **Achievement Progression Calculation**: Fixed integer division truncation in `PlayerActivitiesDatabase.SetAchievements` before `Math.Ceiling`.
- **Cryptographic Cleanup**: Removed redundant 10-iteration loop in `Encryption.GenerateRandomSalt`.

---

## [1.1.1] - 2025-10-04

### Changed
- Updated localizations via Crowdin.
- UI optimizations.

### Fixed
- Fixed incorrect activity data.
- Fixed EA App data synchronization.
- Fixed Steam data retrieval.

---

## [1.1] - 2024-05-15

### Added
- Added elements for custom theme integration.
- Allowed right-clicking on games list.

### Changed
- Updated localizations.
- Minor optimizations.

### Fixed
- Fixed bug on length of games list for friends data.

---

## [1.0] - 2022-09-23

### Changed
- Migrated to Playnite 10 (Playnite 10 only).
- Updated localizations.

### Fixed
- Fixed minor bugs.

---

## [0.2.1] - 2022-06-15

### Changed
- Updated localizations.
- UI tweaks.

### Fixed
- Fixed issues with HowLongToBeat plugin data.
- Fixed issues with friends data.
- Fixed many issues and crashes.

---

## [0.2] - 2022-04-08

### Added
- Added new friend data (when exists).
- Added friend detail view (when exists).
- Added filters on the timeline view.

### Changed
- Removed automatic refresh of friend data.
- Updated localizations.
- UI tweaks.

---

## [0.1] - 2022-03-30

### Added
- Added Steam friends data.
- Added GOG friends data.
- Added Origin friends data (when public).
- Added playtime data tracking.
- Added SuccessStory plugin data integration.
- Added HowLongToBeat plugin data integration.
- Added ScreenshotsVisualizer plugin data integration.

---

## [Legacy]

Historical releases prior to Keep a Changelog adoption are archived from `manifest/Lacro59_PlayerActivities.yaml`.
