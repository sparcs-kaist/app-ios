import { cp, mkdir, rm } from "node:fs/promises";

await rm("dist", { recursive: true, force: true });
await mkdir("dist/server", { recursive: true });
await mkdir("dist/.openai", { recursive: true });

await cp("build/client", "dist/client", { recursive: true });
await cp("hosting/worker.js", "dist/server/index.js");
await cp("hosting/wrangler.json", "dist/server/wrangler.json");
await cp(".openai/hosting.json", "dist/.openai/hosting.json");
