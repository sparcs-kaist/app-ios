import { createReadStream, createWriteStream } from "node:fs";
import { pipeline } from "node:stream/promises";
import { createGzip, constants } from "node:zlib";

const packageDirectory = "swift/.build/plugins/PackageToJS/outputs/Package";

await pipeline(
  createReadStream(`${packageDirectory}/BuddyWebCore.wasm`),
  createGzip({ level: constants.Z_BEST_COMPRESSION }),
  createWriteStream(`${packageDirectory}/BuddyWebCore.wasm.gz`),
);
