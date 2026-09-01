import type { BuddyWebEngine } from "../../swift/.build/plugins/PackageToJS/outputs/Package/bridge-js";
import compressedModuleURL from "../../swift/.build/plugins/PackageToJS/outputs/Package/BuddyWebCore.wasm.gz?url";

let enginePromise: Promise<BuddyWebEngine> | null = null;

async function loadCompressedModule() {
  if (!("DecompressionStream" in globalThis)) {
    throw new Error("Buddy requires a browser with gzip stream support.");
  }
  const response = await fetch(compressedModuleURL);
  if (!response.ok || !response.body) {
    throw new Error("Buddy could not download its shared Swift core.");
  }

  // Static hosts (including Vite preview) may transparently decode `.gz`
  // assets when they send `Content-Encoding: gzip`. In that case the Fetch
  // body is already the raw wasm module and running it through a second gzip
  // decoder fails before the feed can render.
  if (response.headers.get("content-encoding")?.toLowerCase().includes("gzip")) {
    return response.arrayBuffer();
  }

  const decompressed = response.body.pipeThrough(new DecompressionStream("gzip"));
  return new Response(decompressed).arrayBuffer();
}

export function getBuddyEngine() {
  if (!enginePromise) {
    enginePromise = Promise.all([
      import("../../swift/.build/plugins/PackageToJS/outputs/Package/instantiate.js"),
      import("../../swift/.build/plugins/PackageToJS/outputs/Package/platforms/browser.js"),
      loadCompressedModule(),
    ]).then(async ([{ instantiate }, { defaultBrowserSetup }, module]) => {
      const setup = await defaultBrowserSetup({ module, getImports: () => ({}) });
      const { exports } = await instantiate(setup);
      return new exports.BuddyWebEngine();
    });
  }
  return enginePromise;
}

export function browserLanguage() {
  return typeof navigator === "undefined" ? "en" : navigator.language;
}
