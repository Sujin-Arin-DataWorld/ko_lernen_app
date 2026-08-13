#!/usr/bin/env node
/**
 * read_tester_feedback.cjs — 테스터 피드백 수신함 리더 (관리자 전용).
 *
 * 피드백은 앱 → Cloud Function `submitTesterFeedback`(europe-west3) → Firestore
 *   users/{uid}/tester_feedback/{completionId}
 * 에 저장된다. 이 컬렉션은 firestore.rules 에서 클라이언트 read 가 완전 차단(`if false`)이라
 * **Admin SDK(규칙 우회)로만** 읽을 수 있다. 사용자별 서브컬렉션이므로 전량을 보려면
 * collectionGroup('tester_feedback') 쿼리가 필요하다.
 *
 * 인증(둘 중 하나, 최초 1회):
 *   1) gcloud auth application-default login      ← 권장(현재 gcloud 가 ko-lernen-app 로 설정됨)
 *   2) export GOOGLE_APPLICATION_CREDENTIALS=/경로/service-account.json
 *
 * 사용:
 *   node scripts/admin/read_tester_feedback.cjs                # 최근 50건 표
 *   node scripts/admin/read_tester_feedback.cjs --limit 200
 *   node scripts/admin/read_tester_feedback.cjs --status new   # (인덱스 필요, 아래 참고)
 *   node scripts/admin/read_tester_feedback.cjs --json         # 원본 JSON 덤프
 *   node scripts/admin/read_tester_feedback.cjs --since 2026-08-01
 *
 * `--status new` 는 (status ASC, createdAt DESC) collectionGroup 복합 인덱스를 요구한다.
 * firestore.indexes.json 에 추가돼 있으니 `firebase deploy --only firestore:indexes` 후 사용.
 * 기본 쿼리(createdAt 정렬만)는 자동 단일필드 인덱스로 인덱스 배포 없이 동작한다.
 */
'use strict';

const path = require('path');

const PROJECT_ID = 'ko-lernen-app';
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// firebase-admin 은 레포 루트 node_modules 에 설치돼 있다(별도 설치 불필요).
// Node 의 상위 디렉터리 탐색으로 bare require 가 먼저 해석되고,
// 실패 시 명시 경로들을 순서대로 시도한다.
function loadFirebaseAdmin() {
  const candidates = [
    'firebase-admin',
    path.join(REPO_ROOT, 'node_modules', 'firebase-admin'),
    path.join(REPO_ROOT, 'functions', 'gye', 'node_modules', 'firebase-admin'),
  ];
  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch (_) {
      // 다음 후보 시도
    }
  }
  return null;
}

const admin = loadFirebaseAdmin();
if (!admin) {
  console.error(
    'firebase-admin 를 찾지 못했습니다. 레포 루트에서 `npm install` 을 먼저 실행하세요.',
  );
  process.exit(1);
}

function parseArgs(argv) {
  const args = { limit: 50, json: false, status: null, since: null };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--json') {
      args.json = true;
    } else if (token === '--limit') {
      args.limit = Math.max(1, Number.parseInt(argv[(i += 1)], 10) || 50);
    } else if (token === '--status') {
      args.status = argv[(i += 1)] || null;
    } else if (token === '--since') {
      args.since = argv[(i += 1)] || null;
    }
  }
  return args;
}

function uidFromPath(refPath) {
  // users/{uid}/tester_feedback/{docId}
  const parts = refPath.split('/');
  return parts.length >= 2 ? parts[1] : '(unknown)';
}

function fmtTime(value) {
  if (value && typeof value.toDate === 'function') {
    return value.toDate().toISOString().replace('T', ' ').slice(0, 19);
  }
  return '(no createdAt)';
}

function pick(data, keys) {
  const out = [];
  for (const key of keys) {
    if (data[key] !== undefined && data[key] !== null && data[key] !== '') {
      out.push(`${key}=${data[key]}`);
    }
  }
  return out.join('  ');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  let query = db.collectionGroup('tester_feedback');
  if (args.status) {
    query = query.where('status', '==', args.status);
  }
  if (args.since) {
    const sinceDate = new Date(args.since);
    if (!Number.isNaN(sinceDate.getTime())) {
      query = query.where('createdAt', '>=', sinceDate);
    }
  }
  query = query.orderBy('createdAt', 'desc').limit(args.limit);

  let snap;
  try {
    snap = await query.get();
  } catch (error) {
    const message = String(error && error.message);
    if (/could not (refresh access token|load the default credentials)|UNAUTHENTICATED|Could not load the default credentials/i.test(message)) {
      console.error(
        '인증 실패: Application Default Credentials 가 없습니다.\n' +
          '  아래를 1회 실행 후 다시 시도하세요:\n' +
          '    gcloud auth application-default login\n',
      );
      process.exit(2);
    }
    if (/index/i.test(message) && /https?:\/\//.test(message)) {
      console.error(
        '복합 인덱스가 필요합니다. --status 는 (status, createdAt) collectionGroup 인덱스를 요구합니다.\n' +
          'firestore.indexes.json 에 이미 추가돼 있으니 배포하세요:\n' +
          '    firebase deploy --only firestore:indexes\n' +
          '원본 오류:\n  ' + message,
      );
      process.exit(3);
    }
    throw error;
  }

  if (args.json) {
    const rows = snap.docs.map((doc) => ({
      uid: uidFromPath(doc.ref.path),
      docId: doc.id,
      ...doc.data(),
    }));
    console.log(JSON.stringify(rows, null, 2));
    return;
  }

  if (snap.empty) {
    console.log('수신된 테스터 피드백이 없습니다 (0건).');
    console.log(
      '\n참고: submitTesterFeedback 함수가 europe-west3 에 배포돼 있고, 앱이 ' +
        '--dart-define=ENABLE_TESTER_FEEDBACK=true 로 빌드된 Android 기기에서 ' +
        '제출됐을 때만 이 컬렉션에 데이터가 쌓입니다.',
    );
    return;
  }

  const byType = new Map();
  const byCategory = new Map();

  console.log(`=== 테스터 피드백 최근 ${snap.size}건 (createdAt 내림차순) ===\n`);
  for (const doc of snap.docs) {
    const data = doc.data();
    const uid = uidFromPath(doc.ref.path);
    const when = fmtTime(data.createdAt);
    const type = data.contentType || '(no type)';
    const category = data.category || '(no category)';

    byType.set(type, (byType.get(type) || 0) + 1);
    byCategory.set(category, (byCategory.get(category) || 0) + 1);

    console.log(`● ${when}  [${category}]  ${type}  · ${data.status || 'new'}`);
    const line1 = pick(data, ['contentId', 'contentLabel', 'level', 'scoreSummary']);
    if (line1) console.log(`   ${line1}`);
    const line2 = pick(data, [
      'contentSignal',
      'contentFocus',
      'experienceSignal',
      'experienceFocus',
      'issueArea',
      'bugFrequency',
      'bugImpact',
    ]);
    if (line2) console.log(`   ${line2}`);
    if (data.message) console.log(`   💬 ${String(data.message).replace(/\n/g, ' ')}`);
    if (data.expectedOutcome) console.log(`   기대: ${data.expectedOutcome}`);
    if (data.actualOutcome) console.log(`   실제: ${data.actualOutcome}`);
    console.log(`   uid=${uid}  feedbackId=${data.feedbackId || doc.id}`);
    console.log('');
  }

  console.log('--- 요약 ---');
  console.log('유형별: ' + [...byType].map(([k, v]) => `${k}:${v}`).join('  '));
  console.log('분류별: ' + [...byCategory].map(([k, v]) => `${k}:${v}`).join('  '));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
