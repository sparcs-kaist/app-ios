import type { Exports } from "../../swift/.build/plugins/PackageToJS/outputs/Package/bridge-js";
import compressedModuleURL from "../../swift/.build/plugins/PackageToJS/outputs/Package/BuddyWebCore.wasm.gz?url";

let exportsPromise: Promise<Exports> | null = null;

async function loadCompressedModule() {
  if (!("DecompressionStream" in globalThis)) {
    throw new Error("Buddy requires a browser with gzip stream support.");
  }
  const response = await fetch(compressedModuleURL);
  if (!response.ok || !response.body) {
    throw new Error("Buddy could not download its shared Swift core.");
  }

  // Static hosts may transparently decode `.gz` assets. Fetch then exposes
  // the raw wasm body, so applying another gzip decoder would fail.
  if (response.headers.get("content-encoding")?.toLowerCase().includes("gzip")) {
    return response.arrayBuffer();
  }

  const decompressed = response.body.pipeThrough(new DecompressionStream("gzip"));
  return new Response(decompressed).arrayBuffer();
}

/// Instantiates the app-wide Swift runtime once. Feature clients create their
/// own engine instances from these exports and own their feature lifecycles.
export function getBuddyWasmExports() {
  if (!exportsPromise) {
    exportsPromise = Promise.all([
      import("../../swift/.build/plugins/PackageToJS/outputs/Package/instantiate.js"),
      import("../../swift/.build/plugins/PackageToJS/outputs/Package/platforms/browser.js"),
      loadCompressedModule(),
    ]).then(async ([{ instantiate }, { defaultBrowserSetup }, module]) => {
      const setup = await defaultBrowserSetup({ module, getImports: () => ({}) });
      const { exports } = await instantiate(setup);
      return exports;
    });
  }
  return exportsPromise;
}
