# 📜 남포 GOGO 개발 헌법 (MASTER CONTROL CONSTITUTION)

이 헌법은 남포고고(NAMPO GOGO) 프로젝트의 최고 원칙이며, 개발자·AI·관제실 모두가 반드시 준수해야 하는 최상위 안전 규범입니다.

---

### 제1조 (생산 원본 및 데이터 보호)
Production 원본 소스 및 Production DB 데이터는 대표(PM)의 사전 서면/시스템 승인 없이 임의 수정, 생성, 삭제하지 않는다.

### 제2조 (데이터 변경 전 검증)
중요 데이터나 포인트를 변경하기 전, 반드시 진실의 출처(Source of Truth)와 정확한 사용자 식별자(Canonical Identity)를 사전 검증한다.

### 제3조 (추측 및 임의 대치 금지)
추측 ID, 축약 ID, 비슷한 이름 대치, `User.first` fallback 등 불확실한 임의 접근을 엄격히 금지한다.

### 제4조 (파일 2-Key 보호 원칙)
파일 삭제, 이동, 이름 변경은 관제실의 자동 안전 확인과 PM의 삭제 승인이 모두 충족되는 2-Key 원칙에 의해서만 실행한다.

### 제5조 (오류 3단계 분류)
모든 프로젝트 오류는 **🚨 큰 오류 (CRITICAL)**, **⚠️ 중간 오류 (MAJOR)**, **🔧 작은 오류 (MINOR)** 3단계로 엄격히 분류하여 관리한다.

### 제6조 (큰 오류 및 중간 오류 처리)
큰 오류(🚨)는 즉시 개발을 멈추고 최우선 해결하며, 중간 오류(⚠️)는 해당 본선 기능(Feature) 구현 구간에서 묶어서 해결한다.

### 제7조 (작은 오류 묶음 처리 원칙 — CONSTITUTION-ERROR-BATCH-001)
작은 오류(🔧)는 매번 본선 개발을 중단하지 않고 등록하며, 동일 영역에 기본 **3건 이상** 모였을 때(Threshold=3) PM 승인을 거쳐 묶음 처리(Batch)한다.

### 제8조 (오류 등급 상향 재분류)
작은 오류라도 보안, 결제, 포인트 장부, 데이터 손상, 앱 Crash, 로그인에 영향을 주면 즉시 상위 오류(MAJOR/CRITICAL)로 재분류한다.

### 제9조 (생산 DB 쓰기 산술 검산)
모든 Production DB 쓰기 작업은 예상 Insert/Update/Delete 건수와 실제 결과를 산술 검산하고, 장부 합계 수식을 독립 검증한다.

### 제10조 (중복 실행 차단 — Idempotency)
동일한 승인 건이나 중복 위험 작업이 배포/스타트업/API 수준에서 재실행되지 않도록 고유 Idempotency Key를 통해 엄격히 차단한다.

### 제11조 (보고서 독립 검증)
완료 보고서의 `PASS` 표기나 `SOURCE_FILES_CHANGED = 0` 주장을 과신하지 않고, 관제실이 Git Diff, 빌드 이력, DB 상태를 독립적으로 자동 검증한다.

### 제12조 (실기기 UI 검수 수용)
실기기 UI 검수가 필요한 작업은 PM의 실기기 화면 터치 및 눈으로 확인(Visual Acceptance)이 완료되기 전까지 최종 완료 처리하지 않는다.

### 제13조 (불확실성의 UNKNOWN 명시)
정확히 확인되지 않은 사실이나 시간, 원인은 추측으로 채우지 않고 `UNKNOWN` 상태로 명확히 기록한다.

### 제14조 (역사적 기록 보존)
과거의 오류, 잘못된 시도, 정정 이력은 삭제하지 않으며 `SUPERSEDED` 또는 `RESOLVED` 형태로 투명하게 남긴다.

### 제15조 (관제실과 생산 앱의 독립성)
MASTER CONTROL은 독립된 Control Plane이며, Production 백엔드/앱 런타임은 관제실에 코드나 실행 의존성을 가지지 않는다.

### 제16조 (변경 연계 부위 검사 — MUST_CO_CHECK)
특정 모듈이나 기능을 변경할 때는 연관된 `MUST_CO_CHECK` 연계 부위를 반드시 함께 사전/사후 검사한다.

### 제17조 (무관 기능 보호 — MUST_NOT_TOUCH)
현재 작업 대상이 아닌 기존 결제, 회원, 미션, Spatial 등 `MUST_NOT_TOUCH` 지정 영역은 어떠한 사이드 이펙트도 미치지 않도록 보호한다.

### 제18조 (본선 개발 촉진)
안전장치 강화가 본선 개발을 영구 지연시켜서는 안 되며, 관제실 검증 통과 시 즉시 본선 개발(MAP/SPATIAL 등)로 신속히 복귀한다.


---

### 📜 역사 및 시각 기록 운영 수칙 (HISTORY & TIME RULES)

- **CONSTITUTION-HISTORY-TIME-001**: 확실하지 않은 날짜와 시각을 임의 추측하여 생성하지 않는다. 증거가 부족한 시각은 `TIME=UNKNOWN` (시간 미상)으로 표기한다.
- **HISTORY-01**: 프로젝트의 주요 작업, 오류, 수정, 배포, PM 결정은 Master Chronicle 및 Timeline Events에 기록한다.
- **HISTORY-02**: 모든 날짜와 시각은 Git Commit, 빌드/설치 로그, PM 관측 기록 등 명확한 증거(Evidence)에 기반한다. Git commit 시각은 코드 저장 시각일 뿐 오류 관측 시각과 동일시하지 않는다.
- **HISTORY-03**: 오류 해결 및 교정 기록을 과거 데이터에서 지우지 않고 `SUPERSEDED` 또는 `RESOLVED` 상태로 보존한다.
- **HISTORY-04**: 개발 일지는 날짜별 그룹핑 및 시각 순서로 투명하게 조회 가능하도록 제공한다.

### CONSTITUTION-DEVENV-MEM-001 (MEMORY GOVERNANCE & PREFLIGHT)
- **WARNING Threshold**: language_server >= 3GB
- **RESTART_RECOMMENDED Threshold**: language_server >= 5GB
- **DO_NOT_START_LARGE_AGENT_TASK Threshold**: System RAM >= 85%
- Before launching large agent tasks, execute MEMORY_PREFLIGHT (check system RAM, language_server RSS, workspace root scope).
- Build artifacts (`04_Source_Code/frontend/build/**`), `.dart_tool/**`, `.gradle/**`, `__pycache__/**` MUST be excluded from watcher/indexing via `.vscode/settings.json`.
