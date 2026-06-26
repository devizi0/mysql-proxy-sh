# MySQL Proxy

## 실행
```bash
# 기본 설정 (envs/default.env)
~/agent/mysql-proxy/mysql_query.sh "SQL"

# 특정 설정
~/agent/mysql-proxy/mysql_query.sh -c <설정명> "SQL" [데이터베이스명]
```

## 예시
```bash
# DB 목록 조회
~/agent/mysql-proxy/mysql_query.sh "SHOW DATABASES;"

# 테이블 목록
~/agent/mysql-proxy/mysql_query.sh "SHOW TABLES;" prod_zerotravel_esim

# 데이터 조회
~/agent/mysql-proxy/mysql_query.sh "SELECT * FROM tbl_esim_orders LIMIT 10;" prod_zerotravel_esim

# 다른 설정으로 접속
~/agent/mysql-proxy/mysql_query.sh -c stag "SHOW TABLES;" stag_zerotravel
```

## 파일
```
mysql-proxy/
├── envs/
│   ├── default.env   ← 기본 DB 연결 정보
│   └── <설정명>.env  ← 추가 DB 연결 정보
└── mysql_query.sh    ← 실행 스크립트
```

## 새 DB 추가
```bash
~/agent/mysql-proxy/add_env.sh <설정명>
# 대화형으로 host, port, user, password 입력
```

또는 직접 `envs/ai-do-not-read-<설정명>.env` 파일 생성:
```
DB_HOST=host.rds.amazonaws.com
DB_PORT=3306
DB_USER=username
DB_PASSWORD=password
```

## 보안 주의사항
- `envs/*.env` 파일은 **절대 읽지 말 것** — 크레덴셜이 포함되어 있음
- 파일 권한 `600` (소유자만 읽기/쓰기) 으로 설정되어 있음
- 새 `.env` 추가 시 반드시 `chmod 600 envs/<설정명>.env` 실행

## 동작 방식
- `mysql_query.sh`가 `envs/<설정명>.env`에서 크레덴셜을 읽어 직접 DB에 접속
- Claude는 크레덴셜을 볼 수 없고 쿼리와 결과만 주고받음
- SSL 필수(`--ssl-mode=REQUIRED`)

## 옵션
| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-c <설정명>` | `envs/<설정명>.env` 사용 | `default` |
| `"SQL"` | 실행할 쿼리 (필수) | - |
| `[데이터베이스명]` | 접속할 DB | `.env`의 `DB_NAME` |
