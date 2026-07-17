# Nampo GoGo Source Code v0.1

## 구성

- backend: FastAPI 서버
- frontend: Flutter 앱 생성 위치
- database: PostgreSQL 관련 파일
- infrastructure: 배포/운영 설정
- docker-compose.yml: 백엔드와 DB를 함께 실행

## 현재 상태

프로젝트 골격 생성 완료.
기능 개발 전 단계입니다.

## 초보자 실행 순서

1. `.env.example`을 복사하여 `.env`로 이름 변경
2. `.env` 안의 `CHANGE_ME` 값을 안전한 값으로 변경
3. Docker Desktop 실행
4. 이 폴더에서 터미널 열기
5. 아래 명령 실행

```bash
docker compose up --build
```

6. 브라우저에서 확인

```text
http://localhost:18080/health
```

정상 결과:

```json
{"status":"ok"}
```
