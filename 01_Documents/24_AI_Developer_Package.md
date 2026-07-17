# 24. AI Developer Package

## 목적
이 문서는 AI 개발 에이전트가 남포 GoGo 프로젝트를 바로 이해하고 개발을 시작하기 위한 기준 문서이다.

## 문서 읽는 순서
1. 25_README_START_HERE.md
2. 00_Project_Constitution.md
3. 01_Master_Project.md
4. 03_Requirement_Specification.docx
5. 04_Functional_Specification.docx
6. 08_Database_Design.docx
7. 09_API_Specification.docx

## 개발 우선순위
1. 프로젝트 초기화
2. 인증(Auth)
3. 사용자 및 권한
4. 매장
5. 미션
6. 쿠폰
7. QR/GPS 인증
8. AI 추천
9. 관리자 기능
10. 테스트 및 배포

## 기본 원칙
- Master Project를 기준으로 개발한다.
- Expansion Project 기능은 구현하지 않는다.
- 모든 변경은 Decision Log와 Change Log에 기록한다.
- 추측하지 말고 문서를 기준으로 구현한다.
- 보안 정책과 권한 정책을 준수한다.

## 권장 기술 스택
- Flutter
- FastAPI
- PostgreSQL
- Redis
- Docker

## 완료 기준
- 문서와 구현이 일치한다.
- 테스트 체크리스트를 통과한다.
