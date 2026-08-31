# cloud_backup_deletion_runtime.test.js

> 38 nodes · cohesion 0.07

## Key Concepts

- **cloud_backup_deletion_runtime.test.js** (36 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **createTransactionalFirestoreHarness()** (9 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **createCloudBackupDeletionRuntime()** (7 connections) — `functions/gye/cloud_backup_deletion_runtime.js`
- **createFirestoreCloudBackupStore()** (4 connections) — `functions/gye/cloud_backup_deletion_runtime.js`
- **createHarness()** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **FakeFirestoreCollectionReference** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **FakeFirestoreDocumentReference** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **FakeFirestoreSnapshot** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **.listDocumentsPage()** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **safeError()** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **TokenCheckpointBackupStore** (3 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **CursorPagingBackupStore** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **.listDocumentsPage()** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **firestoreCollectionIds()** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **firestoreDocumentIds()** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **keysetPage()** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **NonAdvancingCollectionTokenBackupStore** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **NonAdvancingDocumentTokenBackupStore** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **.listDocumentsPage()** (2 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **assert** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **{
  BACKUP_FIELDS,
  BACKUP_ROOTS,
  CALLABLE_OPTIONS,
  createCloudBackupDeletionCallable,
  createCloudBackupDeletionRuntime,
  createFirestoreCloudBackupDeletionRepository,
  createFirestoreCloudBackupStore,
}** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **callableRequest()** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **{ createHmac }** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **expectPageTokenWasUsed()** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- **fakeFieldDelete** (1 connections) — `functions/gye/cloud_backup_deletion_runtime.test.js`
- *... and 13 more nodes in this community*

## Relationships

- [cloud_backup_deletion_runtime.js](cloud_backup_deletion_runtime.js.md) (8 shared connections)
- [createFirestoreCloudBackupDeletionRepository](createFirestoreCloudBackupDeletionRepository.md) (3 shared connections)
- [gye/index.js](gye-index.js.md) (2 shared connections)
- [FakeTransactionalFirestore](FakeTransactionalFirestore.md) (2 shared connections)
- [MemoryOperationRepository](MemoryOperationRepository.md) (1 shared connections)
- [MemoryBackupStore](MemoryBackupStore.md) (1 shared connections)
- [FencedMemoryBackupStore](FencedMemoryBackupStore.md) (1 shared connections)

## Source Files

- `functions/gye/cloud_backup_deletion_runtime.js`
- `functions/gye/cloud_backup_deletion_runtime.test.js`

## Audit Trail

- EXTRACTED: 60 (92%)
- INFERRED: 5 (8%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*