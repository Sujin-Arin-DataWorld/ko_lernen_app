import { rm } from "node:fs/promises";
import { resolve } from "node:path";
import {
  buildIdentityPath,
  resolveBuildReleaseIdentity,
  writeBuildReleaseIdentity,
} from "./release-id.mjs";

const projectRoot = resolve(import.meta.dirname, "..");

await rm(resolve(projectRoot, "dist"), { recursive: true, force: true });
await rm(buildIdentityPath, { force: true });
const identity = await writeBuildReleaseIdentity(
  await resolveBuildReleaseIdentity(),
);
console.log(`Prepared build release ${identity.releaseId}.`);
