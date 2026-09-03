"use strict";
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { ref, uploadBytes, getMetadata, listAll } = require("firebase/storage");
let environment;
const canonical = "tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3";
const unknown = "tts/v3/female/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.mp3";
const personal = "tts_private/alice/v3/female/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.mp3";
test.before(async () => {
  environment = await initializeTestEnvironment({ projectId: "demo-hangul-sori",
    storage: { rules: fs.readFileSync(path.resolve(__dirname, "../../storage.rules"), "utf8") },
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const storage = context.storage();
    await uploadBytes(ref(storage, canonical), new Uint8Array([1]), { customMetadata: { canonical: "true" } });
    await uploadBytes(ref(storage, unknown), new Uint8Array([1]));
    await uploadBytes(ref(storage, personal), new Uint8Array([1]), { customMetadata: { expiresAtMillis: String(Date.now() + 86400000) } });
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
