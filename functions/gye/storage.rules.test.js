"use strict";
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { ref, uploadBytes, getMetadata, listAll, deleteObject } = require("firebase/storage");
let environment;
const canonical = "tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3";
const unknown = "tts/v3/female/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.mp3";
const personal = "tts_private/alice/v3/female/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.mp3";
const artwork = `learning-art/v1/${"a".repeat(64)}.png`;
const webpArtwork = `learning-art/v1/${"b".repeat(64)}.webp`;
const unapprovedArtwork = `learning-art/v1/${"c".repeat(64)}.png`;
const wrongTypeArtwork = `learning-art/v1/${"d".repeat(64)}.png`;
const invalidNameArtwork = "learning-art/v1/not-a-digest.png";
const missingMetadataArtwork = `learning-art/v1/${"e".repeat(64)}.png`;
const mismatchedImageType = `learning-art/v1/${"f".repeat(64)}.png`;
const invalidExtension = `learning-art/v1/${"a".repeat(64)}Xpng`;
test.before(async () => {
  environment = await initializeTestEnvironment({ projectId: "demo-hangul-sori",
    storage: { rules: fs.readFileSync(path.resolve(__dirname, "../../storage.rules"), "utf8") },
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const storage = context.storage();
    await uploadBytes(ref(storage, canonical), new Uint8Array([1]), { customMetadata: { canonical: "true" } });
    await uploadBytes(ref(storage, unknown), new Uint8Array([1]));
    await uploadBytes(ref(storage, personal), new Uint8Array([1]), { customMetadata: { expiresAtMillis: String(Date.now() + 86400000) } });
    for (const [asset, contentType, canonical] of [
      [artwork, "image/png", "true"],
      [webpArtwork, "image/webp", "true"],
      [unapprovedArtwork, "image/png", "false"],
      [wrongTypeArtwork, "text/html", "true"],
      [invalidNameArtwork, "image/png", "true"],
      [mismatchedImageType, "image/webp", "true"],
      [invalidExtension, "image/png", "true"],
    ]) {
      await uploadBytes(ref(storage, asset), new Uint8Array([1]), {
        contentType, customMetadata: { canonical },
      });
    }
    await uploadBytes(ref(storage, missingMetadataArtwork), new Uint8Array([1]), { contentType: "image/png" });
  });
});
test.after(async () => environment?.cleanup());
test("public may get approved canonical object but cannot list or read unknown legacy", async () => {
  const storage = environment.unauthenticatedContext().storage();
  await assertSucceeds(getMetadata(ref(storage, canonical)));
  await assertFails(getMetadata(ref(storage, unknown)));
  await assertFails(listAll(ref(storage, "tts")));
  await assertFails(listAll(ref(storage, "tts/v3/female")));
});
test("private object reads are callable-only, even for owner; cross UID is denied", async () => {
  for (const uid of ["alice", "bob"]) {
    const storage = environment.authenticatedContext(uid).storage();
    await assertFails(getMetadata(ref(storage, personal)));
    await assertFails(listAll(ref(storage, "tts_private/alice")));
    await assertFails(uploadBytes(ref(storage, unknown), new Uint8Array([1]), { customMetadata: { canonical: "true" } }));
  }
});

test("approved immutable Hanok PNG and WebP are public get-only", async () => {
  for (const context of [environment.unauthenticatedContext(), environment.authenticatedContext("alice")]) {
    const storage = context.storage();
    await assertSucceeds(getMetadata(ref(storage, artwork)));
    await assertSucceeds(getMetadata(ref(storage, webpArtwork)));
    await assertFails(listAll(ref(storage, "learning-art/v1")));
    await assertFails(uploadBytes(ref(storage, artwork), new Uint8Array([2]), {
      contentType: "image/png", customMetadata: { canonical: "true" },
    }));
    await assertFails(deleteObject(ref(storage, artwork)));
  }
});

test("unapproved, malformed and non-image Hanok objects stay private", async () => {
  const storage = environment.unauthenticatedContext().storage();
  for (const asset of [unapprovedArtwork, wrongTypeArtwork, invalidNameArtwork, missingMetadataArtwork, mismatchedImageType, invalidExtension]) {
    await assertFails(getMetadata(ref(storage, asset)));
  }
});
