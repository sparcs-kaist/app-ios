# macOS native build handoff

This document supersedes the handoff written on
`experiment/macos-channel-talk-isolation` (commit `5c28afb`). That branch was
prepared without access to Xcode, so every question it left open is answered
here with measured results.

## Environment the results below were produced on

| | |
|---|---|
| macOS | 26.5.1 (25F80) |
| Xcode | 26.5 (17F42) |
| Swift | 6.3.2 (swiftlang-6.3.2.1.108) |
| Branch | `fix@mac-catalyst-ui` |
| Base | `a6b305f7 fix widget presenting negative D-Day (#139)` |
| Scheme / destination | `soap` / `platform=macOS,arch=arm64` |

## Result

The macOS build succeeds and the app runs as a native arm64 Mach-O binary. It
is not a Mac Catalyst build and not a "Designed for iPad" build.

```
xcodebuild -scheme soap -destination 'platform=macOS,arch=arm64' \
  -configuration Debug build
** BUILD SUCCEEDED **
```

iOS and watchOS builds are unaffected. Extensions and the watch app are embedded
on iOS and excluded on macOS.

## What the real blocker turned out to be

The experiment branch assumed ChannelTalk was the first blocker. It was not.

Seven local SwiftPM packages declared only `.iOS` (and `.watchOS`) in their
`platforms:` list. SwiftPM therefore fell back to a macOS 10.13 deployment
target for them and package graph resolution failed **before any UIKit symbol
was ever reached**:

```
error: the library 'BuddyDomain' requires macos 10.13, but depends on the
       product 'Factory' which requires macos 10.15
```

The same failure surfaces in Xcode as the `The package product 'X' requires
minimum platform version 10.15 for the macOS platform` diagnostics. Those come
from package resolution, not compilation, which is why they appear before any
source file is compiled.

Declaring `.macOS(.v26)` on all seven packages removed the resolution failure
and let the actual UIKit work begin. ChannelTalk was one of only two iOS-only
dependencies encountered afterwards.

## How the build was solved, in order

### 1. Package graph resolution

Added `.macOS(.v26)` to `platforms:` in `BuddyDomain`, `BuddyData`,
`BuddyDataiOS`, `BuddyFeature`, `BuddyUI`, `BuddyPreviewSupport` and
`BuddyTestSupport`.

### 2. iOS-only dependencies

Only two exist:

- **Haptica** — a thin wrapper over `UIImpactFeedbackGenerator`. Removed
  entirely and replaced with the `BuddyHaptic` abstraction, so nothing is
  conditionally linked.
- **ChannelIOSDK** — an xcframework with no macOS slice. Restricted to iOS in
  two places, both of which are required:
  - `BuddyFeature/Package.swift`: `condition: .when(platforms: [.iOS])`
  - `soap.xcodeproj/project.pbxproj`: `platformFilters = (ios, )` on the
    `ChannelIOSDK in Frameworks` build file

  The second one is the item the experiment branch listed as an unresolved
  known limitation. A `condition:` in the package manifest does not cover a
  product that is also linked directly by the Xcode target; the platform filter
  on the build file is what excludes it from the macOS link.

### 3. Cross-platform primitives

`UIImage`/`UIColor` were used throughout the domain layer, including in
`Sendable` protocol signatures. `NSImage` is not `Sendable`, so a direct
substitution does not compile under Swift 6.

Added `BuddyDomain/Sources/Extension/PlatformTypes.swift` with `PlatformImage`
and `PlatformColor` aliases plus the `NSImage` `Sendable` conformance, then
substituted across 23 files. Also added `BuddyHaptic`, `BuddyPasteboard` and
`PlatformViewCompat` for the UIKit APIs with no direct AppKit equivalent.

### 4. App lifecycle

`AppDelegate` conforms to `NSApplicationDelegate` on macOS and
`UIApplicationDelegate` on iOS. Navigation uses a sidebar on macOS.

### 5. Feature layer

`SafariViewWrapper` and the web views are platform-split; haptics and clipboard
go through the new abstractions.

### 6. TaxiChat

The transcript was a `UIViewRepresentable` over `UICollectionView`, which has no
AppKit counterpart worth bridging. Rewritten in SwiftUI using `ScrollView` +
`LazyVStack`.

## Remaining blocker: code signing, not compilation

Building for **My Mac** in Xcode still fails on a machine without a signed-in
account for team `N5V8W52U3U`:

```
No Account for Team "N5V8W52U3U". Add a new account in Accounts settings
  or verify that your accounts have valid credentials.
→ No profiles for 'org.sparcs.soap' were found: Xcode couldn't find any
  Mac App Development provisioning profiles matching 'org.sparcs.soap'.
```

macOS needs its own Mac App Development provisioning profile; the iOS one does
not cover it. This is an account problem, not a code problem — the same tree
builds cleanly with `CODE_SIGNING_ALLOWED=NO`.

To run the app locally without team access, ad-hoc signing works, but the
entitlements must be dropped as well, because `aps-environment`,
`associated-domains` and `application-groups` all require a profile:

```bash
xcodebuild -scheme soap -destination 'platform=macOS,arch=arm64' \
  -configuration Debug build \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" CODE_SIGN_ENTITLEMENTS=""
```

Push notifications, Universal Links and App Group sharing are inert in that
build. It is only useful for UI verification.

## Open items

### ChannelTalk has no macOS replacement yet

The `Chat with Us` entry is compiled out on macOS, so the platform currently has
no in-app support channel. The options are the anonymous web messenger, which
loses `memberId` tracking and push, or a mail fallback. Pending a decision.

### `swift build` / `swift test` do not work from the command line

This is pre-existing and is **not** introduced by this branch, but it is now the
first thing you hit rather than the second:

- On `main`, CLI builds fail at package resolution with the macOS 10.13 error
  above.
- On this branch resolution succeeds and the build then fails with roughly 700
  instances of `'module' is inaccessible due to 'internal' protection level`.

The cause is that the `BuddyDomain` target uses `Bundle.module` while declaring
no `resources:`, so SwiftPM synthesises no accessor and `.module` resolves to
Factory's internal one instead. Both the `Bundle.module` usage and the missing
`resources:` declaration already exist on `main`. Xcode builds are unaffected
because its build system handles `Localizable.xcstrings` differently.

Likely fix is adding `resources: [.process("Localizable.xcstrings")]` to the
`BuddyDomain` target, but it needs verification against both build systems and
is deliberately out of scope here.

### UI issues found on macOS

Verified on the ad-hoc build described above:

- The sign-in icon renders as a hard-edged black square. `dark-logo.png` in
  `BuddyIcon.imageset` has an opaque black background baked in, and
  `SignInView` applies no corner radius, so it clashes with the window
  background.
- The primary CTA loses its entire background when the window is not key, so
  `.glassProminent` leaves only grey text that is indistinguishable from the
  body copy above it.

Sidebar, toolbar placement, sheet sizing and TaxiChat behaviour are still
unverified because they sit behind sign-in.

### `BuddyUITests` does not build

`BuddyUI/Tests/BuddyUITests/BuddyUITests.swift` does `@testable import BuddyUI`,
but no `BuddyUI` target exists — the real targets are `BuddySharedUI`,
`TimetableUI` and the three widget UI targets. Pre-existing, and left alone
because the fix is a team decision about whether the target should exist.
