# gye/index.js

> 99 nodes · cohesion 0.04

## Key Concepts

- **gye/index.js** (135 connections) — `functions/gye/index.js`
- **lifecycle.js** (44 connections) — `functions/gye/lifecycle.js`
- **lifecycle.test.js** (39 connections) — `functions/gye/lifecycle.test.js`
- **deliverNotificationOutboxDocument()** (11 connections) — `functions/gye/index.js`
- **chunkItems()** (6 connections) — `functions/gye/lifecycle.js`
- **settledNotificationTokenHashes()** (6 connections) — `functions/gye/lifecycle.js`
- **accountTombstoneCleanupAction()** (5 connections) — `functions/gye/lifecycle.js`
- **buildWeeklyNotificationOutbox()** (5 connections) — `functions/gye/lifecycle.js`
- **classifyMulticastResponses()** (5 connections) — `functions/gye/lifecycle.js`
- **filterUnsettledNotificationTokens()** (5 connections) — `functions/gye/lifecycle.js`
- **notificationOutboxMaintenanceAction()** (5 connections) — `functions/gye/lifecycle.js`
- **notificationRetryDelayMillis()** (5 connections) — `functions/gye/lifecycle.js`
- **selectSuccessor()** (5 connections) — `functions/gye/lifecycle.js`
- **keyedDeletionProofDigest** (4 connections) — `functions/gye/index.js`
- **releaseNotificationOutboxClaim()** (4 connections) — `functions/gye/index.js`
- **buildNotificationDeliveryUpdate()** (4 connections) — `functions/gye/lifecycle.js`
- **buildOwnerSuspensionPlan()** (4 connections) — `functions/gye/lifecycle.js`
- **isAccountDeletionTombstoneOldEnough()** (4 connections) — `functions/gye/lifecycle.js`
- **isDeliverableGyeLifecycle()** (4 connections) — `functions/gye/lifecycle.js`
- **notificationTerminalExpiryMillis()** (4 connections) — `functions/gye/lifecycle.js`
- **legacyAccountTombstoneCleanupAction()** (3 connections) — `functions/gye/account_operations_runtime.js`
- **claimNotificationOutbox()** (3 connections) — `functions/gye/index.js`
- **finishNotificationOutboxClaim()** (3 connections) — `functions/gye/index.js`
- **notificationTerminalFields()** (3 connections) — `functions/gye/index.js`
- **buildGroupCleanupPlan()** (3 connections) — `functions/gye/lifecycle.js`
- *... and 74 more nodes in this community*

## Relationships

- [deletion_cleanup_adapters.test.js](deletion_cleanup_adapters.test.js.md) (19 shared connections)
- [account_operations_runtime.js](account_operations_runtime.js.md) (15 shared connections)
- [weekly_contribution_runtime.js](weekly_contribution_runtime.js.md) (6 shared connections)
- [deletion_gye_page.js](deletion_gye_page.js.md) (5 shared connections)
- [adapterFailure](adapterFailure.md) (3 shared connections)
- [createDeletionCleanupAdapters](createDeletionCleanupAdapters.md) (3 shared connections)
- [gye_dedication_runtime.js](gye_dedication_runtime.js.md) (3 shared connections)
- [runtime.test.js](runtime.test.js.md) (3 shared connections)
- [apple_revocation_adapter.js](apple_revocation_adapter.js.md) (2 shared connections)
- [cloud_backup_deletion_runtime.js](cloud_backup_deletion_runtime.js.md) (2 shared connections)
- [cloud_backup_deletion_runtime.test.js](cloud_backup_deletion_runtime.test.js.md) (2 shared connections)
- [tester_feedback_runtime.js](tester_feedback_runtime.js.md) (2 shared connections)

## Source Files

- `functions/gye/account_operations_runtime.js`
- `functions/gye/deletion_adapters.js`
- `functions/gye/index.js`
- `functions/gye/lifecycle.js`
- `functions/gye/lifecycle.test.js`

## Audit Trail

- EXTRACTED: 214 (85%)
- INFERRED: 37 (15%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*