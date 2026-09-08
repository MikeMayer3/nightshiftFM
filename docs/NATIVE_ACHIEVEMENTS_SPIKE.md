# M1 native-achievement feasibility — 2026-09-07

**Research completed; native sandbox unlock NOT RUN.** No achievement plugin,
login flow, backend, or purchase SDK is installed in Nightshift FM. The mobile
probe states that native achievements are unavailable. These are candidates for
a later isolated compatibility build, not verified integrations.

| Candidate | Pinned source / license | Evidence and limits |
|---|---|---|
| Android: Godot Play Game Services | [v3.4.0](https://github.com/godot-sdk-integrations/godot-play-game-services/tree/v3.4.0), released 2026-07-20; MIT | Maintained, not archived; README targets Godot 4.3+. Its [build file](https://github.com/godot-sdk-integrations/godot-play-game-services/blob/v3.4.0/plugin/build.gradle.kts) targets Java 17 and Godot Android 4.5.1. Compatibility with our exact 4.7.2 template has **not** been compiled/tested. Requires the Gradle/plugin export path; the current APK uses the standard template path. |
| iOS: GodotApplePlugins GameCenter component | [build-bfade13ff8b6027ede438bac637b5bf93057d404](https://github.com/migueldeicaza/GodotApplePlugins/tree/build-bfade13ff8b6027ede438bac637b5bf93057d404), released 2026-09-02; MIT | Active source/release. Package separates GameCenter from other Apple integrations. README requires iOS 17/macOS 14; Package.swift uses Swift 6.2 and a pinned SwiftGodotBinary revision. This is an investigation candidate for iPhone 16; 4.7.2 binary compatibility and device behavior remain **NOT RUN**. |
| Alternative: Godot iOS plugins, GameCenter | [source caafb2c7fbfb5c72a64f163c76449274fa49abaa](https://github.com/godot-sdk-integrations/godot-ios-plugins/tree/caafb2c7fbfb5c72a64f163c76449274fa49abaa); MIT | Repository active through 2026-07-10, but latest tagged binary release is [3.5-stable from 2022](https://github.com/godot-sdk-integrations/godot-ios-plugins/releases/tag/3.5-stable). Do not install those binaries into 4.7.2. Would need a source build against the pinned engine. |

Release dates/license metadata were checked with GitHub's repositories/releases
API, alongside the pinned README/build sources. Activity and a broad compatibility
claim do not establish binary or runtime compatibility.

The bounded fallback, if candidates fail, is a small native adapter exposing
availability, authentication, unlock, absolute/monotonic progress, and completion
errors. Godot's [Android plugin interface](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html)
and [iOS plugin interface](https://docs.godotengine.org/en/stable/tutorials/platform/ios/plugins_for_ios.html)
are the integration boundaries. No bridge is claimed built in this spike.

## Exact next sandbox test

1. Owner supplies the game's Apple team/bundle setup and a configured sandbox
   achievement; for Android, a Play Games project, OAuth package/certificate
   configuration, tester access, and an achievement ID. No account was created,
   payment made, credential read from another project, or store configuration
   changed during M1.
2. Build only the achievement component in an isolated copy with Godot 4.7.2.
   Record plugin source revision, dependencies/licenses, actual build output,
   device model, and OS. Do not include StoreKit/ARKit/authentication packages
   merely because a candidate bundle offers them.
3. Run on the physical Pixel and iPhone: authenticate with the designated test
   account, submit one sandbox unlock, and observe completion in the native UI.
   Exercise unavailable/sign-out/network-failure cases without blocking core play.
4. Test retry behavior with a monotonic value. Avoid repeating incremental
   achievement steps on uncertain responses. Apple's [GKAchievement](https://developer.apple.com/documentation/gamekit/gkachievement)
   and Google's [achievement APIs](https://developer.android.com/games/pgs/android/achievements)
   are the primary behavior references.

No game-specific account/achievement IDs were provided. There is no connected
physical iPhone. These block the actual native sandbox test; a plugin name or
local test cannot count as a passed native integration. Native achievements are
also not cross-platform cloud saving. Production adapters remain M11 scope.
