# 30. GitHub Project Template

## 목적
남포 GoGo 프로젝트의 Git 운영 규칙과 협업 표준입니다.

# 권장 폴더 구조

```text
/
├── docs
├── backend
├── frontend
├── infrastructure
├── database
├── assets
├── scripts
└── .github
    ├── ISSUE_TEMPLATE
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows
```

# 브랜치 전략

- main : 운영(Production)
- develop : 통합 개발
- feature/* : 기능 개발
- hotfix/* : 긴급 수정
- release/* : 배포 준비

# Commit 규칙 (Conventional Commits)

- feat: 새로운 기능
- fix: 버그 수정
- docs: 문서
- refactor: 리팩터링
- test: 테스트
- chore: 기타 작업

예시:
```text
feat(auth): 소셜 로그인 추가
fix(coupon): 중복 발급 오류 수정
docs(api): OpenAPI 업데이트
```

# Pull Request 체크리스트

- [ ] 빌드 성공
- [ ] 테스트 완료
- [ ] 문서 반영
- [ ] Change Log 업데이트
- [ ] Decision Log 확인

# Issue 템플릿

제목:
설명:
재현 방법:
기대 결과:
실제 결과:
우선순위:
담당자:

# CODEOWNERS 예시

```text
/backend/ @backend-team
/frontend/ @frontend-team
/docs/ @pm
```

# .gitignore 추천

```text
.env
.env.*
__pycache__/
node_modules/
.vscode/
.idea/
dist/
build/
*.log
```

# 버전 관리

Semantic Versioning 사용

- MAJOR : 호환되지 않는 변경
- MINOR : 기능 추가
- PATCH : 버그 수정

예)
2.1.0 → 기능 추가
2.1.1 → 버그 수정

# AI 협업 규칙

1. README부터 읽는다.
2. Master Project 기준으로 구현한다.
3. Expansion Project는 구현하지 않는다.
4. Decision Log와 Change Log를 항상 업데이트한다.
5. 보안 정책과 권한 정책을 준수한다.
