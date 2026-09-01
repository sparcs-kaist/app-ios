import type { FeedWebEngine } from "../../../swift/.build/plugins/PackageToJS/outputs/Package/bridge-js";
import { getBuddyWasmExports } from "~/lib/wasm-runtime.client";

let feedEnginePromise: Promise<FeedWebEngine> | null = null;

export function getFeedEngine() {
  if (!feedEnginePromise) {
    feedEnginePromise = getBuddyWasmExports().then(
      ({ FeedWebEngine }) => new FeedWebEngine(),
    );
  }
  return feedEnginePromise;
}
