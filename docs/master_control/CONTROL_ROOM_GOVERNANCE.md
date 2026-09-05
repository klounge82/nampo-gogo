# NAMPO GOGO — CONTROL ROOM PERMANENT GOVERNANCE POLICY

CONTROL_ROOM_GOVERNANCE_VERSION=1
EFFECTIVE_DATE=2026-09-05
AUTHORITY=PM_CANONICAL_GOVERNANCE_LOCK

---

## 1. 목적 (Purpose)
NAMPO GOGO Control Room은 프로젝트의 장기 기억(Long-Term Project Memory)이자 단일 진실 공급원(Single Source of Truth)입니다.
어떠한 AI 에이전트나 개발자도 시간의 경과, 세션 만료, 컨텍스트 축약 등을 이유로 기존 관제실 규격과 용어 체계를 임의로 재설계하거나 왜곡할 수 없습니다.
본 정책은 관제실 규격을 문서화, 중앙화, 기계 검증화(Machine-Validated)하여 영구적으로 보존하는 것을 목적으로 합니다.

---

## 2. 절대 불변 7대 거버넌스 원칙 (7 Non-Negotiable Principles)

### A. 일관성 우선 (Consistency over Novelty)
- 새로운 세션이 시작되었다고 해서 임의로 새로운 중요도 체계, 배지 색상, 카드 레이아웃, 용어를 고안하지 않습니다.
- 관제실 표시 규격 변경(CANONICAL_FORMAT_CHANGE)은 반드시 PM의 명시적 승인이 있어야만 가능합니다.

### B. 사실 근거 기반 기록 (Evidence over Guessing)
- 과거 기록의 보완은 오직 다음 공식 근거에 의해서만 수행됩니다:
  - Git 커밋 및 diff 증거
  - Change Registry 및 Error Log 원본
  - Timeline Events 및 Master Chronicle
  - 단위/통합 테스트 리포트 및 빌드 아티팩트
  - 삼성 S24 Ultra 실기기 / PC 에뮬레이터 검증 증거
- 근거가 불충분할 경우 절대로 허위 사실을 날조(Fabricate)하지 않으며, 명시적으로 `근거 미확보` 또는 `해당 없음 (사유)`으로 기록합니다.

### C. 신규 기록 완전성 계약 (New Record Completeness Contract)
- 본 정책 활성화 시점(2026-09-05, MC-CHANGE-0093 이후) 이후에 생성되는 모든 신규 변경/오류 기록은 완전 상세 계약(Full Detail Contract)을 100% 충족해야 합니다.
- 필수 항목이 무의미한 `기록 없음`으로 방치되어서는 안 됩니다.

### D. 레거시 기록 처리 정책 (Legacy Record Policy)
- 정책 활성화 이전의 93개 레거시 기록은 과거 상태 그대로 안전하게 보존(Legacy Mode)됩니다.
- 과거 기록을 일괄 훼손하거나 추측성 값으로 오염시키지 않으며, 확실한 증거가 확보된 경우에 한하여 단계적으로 보강합니다.

### E. 소스 우선 대시보드 정책 (Source-First Dashboard Policy)
- 생성된 HTML 파일(`dashboard.html`)은 독립적인 진실 공급원이 아닙니다.
- `CONTROL_ROOM_CONTRACT.json`, `CHANGE_REGISTRY.json`, `ERROR_LOG.json`, `KOREAN_SUMMARIES.json` 및 검증기 코드가 정본(Source of Truth)이며, HTML은 이를 충실히 렌더링한 결과물입니다.

### F. 검증기 사전 게이트 강제 (Validator Gate Before Generator)
- 대시보드 렌더링 전 반드시 `validate_control_room.py` 검증기가 실행되어 `PASS` 판정을 받아야 합니다.
- 검증 실패 시 대시보드 생성 및 배포는 즉시 중단(Hard Stop)됩니다.

### G. 에이전트 기억 의존 금지 (Anti-Forgetting Rule)
- 에이전트의 자체 기억이나 대화 컨텍스트는 관제실 규격의 기준이 될 수 없습니다.
- 모든 관제실 갱신 작업 착수 전 에이전트는 반드시 `CONTROL_ROOM_GOVERNANCE.md`와 `CONTROL_ROOM_CONTRACT.json`을 열람하고, 검증기를 통과시켜야 합니다.

---

## 3. 표준 표시 규격 요약 (Canonical Display Contract)

1. **한국어 요약 라벨**: 반드시 `KR` (중복 단어 없음)
2. **오류 중요도 (Error Severity)**:
   - `CRITICAL` → `🔴 치명적` (`severity-critical`, `#490202`, `#f85149`, `#ff7b72`)
   - `MAJOR` → `🟠 중대` (`severity-major`, `#3d1e03`, `#d29922`, `#e3b341`)
   - `MEDIUM` → `🟡 보통` (`severity-medium`, `#332b00`, `#bb8009`, `#d29922`)
   - `MINOR` → `🔵 경미` (`severity-minor`, `#0c2d6b`, `#388bfd`, `#79c0ff`)
   - `INFO` → `⚪ 정보` (`severity-info`, `#21262d`, `#30363d`, `#8b949e`)
3. **작업 중요도 (Work Importance / Risk)**:
   - `HIGH` → `🟠 중대` (`importance-high`)
   - `MEDIUM` → `🟡 보통` (`importance-medium`)
   - `LOW` → `🔵 경미` (`importance-low`)
   - 사용자 화면에 영문 `LOW/MEDIUM/HIGH`를 원문 그대로 노출하지 않음.
4. **카드 헤더 순서**:
   - 변경: `[작업]` `[중요도 배지]` `[일시]` | `[ID]` `[제목]` → 우측 `[상태]`
   - 오류: `[오류]` `[중요도 배지]` `[일시]` | `[ID]` `[제목]` → 우측 `[상태]`
5. **요약 위치**:
   - 헤더 바로 아래 좌측 강조 라인이 적용된 `KR` 박스 상시 노출.

---

## 4. 영구 갱신 워크플로우 (Permanent Update Workflow)
```
REGISTER (JSON 등록)
  → DETAIL (필수 필드 상세 작성)
  → EVIDENCE LINK (커밋/증거 연결)
  → VALIDATE (python tools/master_control/validate_control_room.py)
  → GENERATE (python tools/master_control/build_dashboard_master_control.py)
  → RENDER AUDIT (생성 HTML 검증)
  → PM REVIEW (PM 최종 검토)
  → STAGE & COMMIT
```

### H. 변경 ID 식별자 및 플레이스홀더 금지 규칙 (No Placeholder IDs)
- 일반 변경 ID에 `MC-CHANGE-0000` 같은 가짜/플레이스홀더(Placeholder) ID 사용은 엄격히 금지됩니다.
- 일반 변경은 `MC-CHANGE-XXXX` 형식의 실제 순번(`MC-CHANGE-0001` ~ `MC-CHANGE-0093` 등) 또는 공인된 하위 개정판(`-R`, `-W` 등)만 허용됩니다.
- 특수 루트/정책/시스템 레코드(예: `MC-03N`, `POLICY-*`)는 일반 변경과 분리된 공식 접두어를 사용합니다.

### I. 초보자 친화형 상세 설명 및 토글 표준화
- 작업 카드의 '무슨 작업인가?' 항목에는 공식 영문/기술 제목뿐만 아니라, 일반 사용자 및 초보자도 한눈에 이해할 수 있도록 **`KR:` 쉬운 한국어 한 줄 설명**을 반드시 함께 표출합니다.
- 상세 토글 문구는 간결하게 **펼침 전: `상세 ▼`**, **펼침 후: `접기 ▲`**로 통일합니다.

---

## 5. 최상단 지휘 뷰 거버넌스 규격 (Top Command View Governance)

관제실 최상단은 PM이 접속하자마자 프로젝트 전체 진행률, 현재 작업, 남은 작업, 헌법 준수 상태를 즉시 파악할 수 있도록 다음 5단계 필수 계층을 엄격히 유지해야 합니다.

```
1. [헤더] 관제실 타이틀 및 생성일시 (HEADER_PANEL)
2. [진행바] 남포고고 전체 진행률 게이지 바 (PROJECT_PROGRESS_BAR)
3. [요약카드] 헌법 상태 / 미해결 오류함 / 총 작업·변경 기록 (SUMMARY_STATUS_CARDS)
4. [헌법조문] 남포고고 개발 헌법 조문 토글 (CONSTITUTION_ARTICLES_TOGGLE)
5. [지휘개요] 현재 작업 / 완료된 작업 / 남은 작업 / 다음 게이트 (CURRENT_REMAINING_WORK_OVERVIEW)
6. [타임라인] 일자별 작업 및 오류 타임라인 (WORK_ERROR_TIMELINE)
```

### J. 진행률 산출 단일 공식 (Single Source Progress Formula)
- 진행률은 임의의 추측이나 하드코딩이 아닌, 공식 로드맵(`NAMPO_PROJECT_CONSTITUTION.md` Section A Major-05A~05I 9대 본선 단계) 및 `CURRENT_STATE_SOT.json`을 단일 진실 공급원으로 합니다.
- **분자 (Numerator)**: 완료된 본선 단계 수 (현재 Major-05A ~ Major-05H = 8개 완료)
- **분모 (Denominator)**: 전체 로드맵 단계 수 (Major-05A ~ Major-05I = 9개)
- **진행률 (Percentage)**: 8 / 9 = 89% (88.89%)
- 어떠한 에이전트도 임의로 100%로 과장하거나 다른 계산식을 날조할 수 없습니다.
