# 🛡️ NAMPO GOGO MASTER CONTROL (남포고고 관제실) v2

> **"관제실의 목적은 남포고고를 대신하는 것이 아니라 남포고고를 더 안전하게 관리하는 것이다."**
> **"관제실이 고장 나거나 삭제되어도 NAMPO GOGO Production 앱/서비스는 100% 정상 작동해야 한다."**

---

## 🏛️ 쉬운 비유 (Beginner PM Guide)

- **NAMPO GOGO APP**: 실제 건축된 건물 (고객이 사용하는 상가/포인트 시스템)
- **MASTER CONTROL**: 설계도 + 공사 일지 + 전기/배관 지도 + 사고 블랙박스 + 안전 관리실 + 공사 허가실

---

## ⚡ 관제실 시작하기 (One-Click Local Starter)

초보 PM도 쉽게 관제실 대시보드를 켤 수 있습니다:

```cmd
:: Windows Explorer에서 아래 파일 더블클릭 또는 커맨드 창 실행:
tools\master_control\start_master_control.bat
```

실행 시 자동으로 브라우저에서 `http://127.0.0.1:18888` 대시보드가 열립니다.

---

## 📜 MASTER CONTROL CONSTITUTION (최상위 헌법)

1. **APP INDEPENDENCE**: Production Runtime은 MASTER CONTROL에 절대 의존하지 않으며, Master Control 파일/코드를 import/참조할 수 없다.
2. **NO SHADOW PRODUCTION**: Production DB의 복제판이나 두 번째 운영 DB 역할을 하지 않으며, 운영 진실 데이터 원본의 위치와 검증 수단만 기록한다.
3. **SOURCE OF TRUTH NEVER REPLACED**: authenticated JWT, `users.current_points`, `UserMission`, `PointHistory` 등 실제 서버 데이터 원본을 Mock/Cache/Master Control 기록으로 대체할 수 없다.
4. **AUTO-READ, NOT DOUBLE-ENTRY**: Git commit, tracked files, API routes, DB schema, migration 등은 자동 수집하며, 사람이 변경 이유 및 안전 정책을 기록한다.
5. **DRIFT DETECTION**: 관제실 기록과 실제 코드/DB의 불일치(Drift) 발견 시 자동 수정하지 않고 `DRIFT_DETECTED` 경고를 발생시킨다.
6. **UNKNOWN IS VALID**: 불확실한 정보는 추측하지 않고 `UNKNOWN`, `UNVERIFIED` 상태로 유지한다.
7. **HISTORY IS APPEND-ONLY**: 과거의 잘못된 판단이나 사고 기록도 삭제하지 않고 `SUPERSEDED` 상태로 이력을 보존한다.
8. **SAFETY BEFORE CONVENIENCE**: Delete, Move, Rename, Replace, Identity Create, Production Write 작업은 자동으로 수행하지 않으며 엄격한 검사를 거친다.
9. **CONTROL PLANE ONLY**: Master Control은 관제·검사·기억 전용 시스템으로, 고객용 서비스를 대신 구현하지 않는다.
10. **KEEP MASTER CONTROL SMALL**: 오류 예방, 원인 추적, 기록 보존, 영향 분석에 직접 도움이 되는 기능만 포함한다.

---

## 🚀 CLI 사용 안내 (CLI Commands)

```bash
# 1. 관제실 전체 상태 확인
python tools/master_control/master_control.py status

# 2. 공사 허가실 사전검사 (Preflight Gate)
python tools/master_control/master_control.py preflight MC-CHANGE-0002

# 3. 로컬 READ-ONLY 대시보드 실행 (127.0.0.1 전용)
python tools/master_control/master_control.py serve

# 4. 파일 안전등급/의존성 조회
python tools/master_control/master_control.py file 04_Source_Code/backend/app/main.py

# 5. Drift 검사
python tools/master_control/master_control.py drift
```
