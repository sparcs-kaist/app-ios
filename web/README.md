# Buddy Web

Buddy Web is the responsive sign-in and feed experience for Buddy. It uses the same React Router/Vite setup as `buddy-front` and shares its feed domain source with iOS through Swift WebAssembly.

## Architecture

- `../shared/BuddyFeedCore` owns feed models, API decoding, relative time, preview data, and the cross-platform feed view model.
- The shared view model drives loading, refresh, pagination, error/notice, and optimistic-vote states on both platforms.
- iOS imports that package through `BuddyDomain`, `BuddyData`, and `BuddyFeature`; each platform still supplies its own HTTP and analytics adapters.
- `swift/` exports the shared core to TypeScript with JavaScriptKit BridgeJS.
- The release module is served gzip-compressed and expanded with the browser stream API before instantiation.
- `app/` contains browser-specific rendering, SPARCS SSO navigation, token storage, and HTTP transport.

## Requirements

- Swift 6.3.3 from Swift.org (not the Xcode-only toolchain)
- Swift 6.3.3 WebAssembly SDK
- Binaryen (`wasm-opt`) for a smaller release module
- Node.js and pnpm

Install the Swift SDK once:

```sh
swift sdk install https://download.swift.org/swift-6.3.3-release/wasm-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_wasm.artifactbundle.tar.gz --checksum cabfa08b73bb8ac783927ecd15fa386e99d0c139c5f232445067bcf58379cae7
```

Then run:

```sh
pnpm install
pnpm dev
```

The build uses the development Buddy APIs by default. Copy `.env.example` to `.env` for overrides. Live sign-in expects SPARCS SSO to return `session` to `/auth/callback`; preview mode remains available during development while that web callback is being registered.
