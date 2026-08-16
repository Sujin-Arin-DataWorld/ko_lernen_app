import { rm } from "node:fs/promises";
import { resolve } from "node:path";
import {
  buildIdentityPath,
  resolveBuildReleaseIdentity,
  writeBuildReleaseIdentity,
} from "./release-id.mjs";

const projectRoot = resolve(import.meta.dirname, "..");
const resilientRemoveOptions = {
  recursive: true,
  force: true,
  maxRetries: 20,
  retryDelay: 250,
};

await rm(resolve(projectRoot, "dist"), resilientRemoveOptions);
await rm(buildIdentityPath, resilientRemoveOptions);
const identity = await writeBuildReleaseIdentity(
  await resolveBuildReleaseIdentity(),
);
console.log(`Prepared build release ${identity.releaseId}.`);
