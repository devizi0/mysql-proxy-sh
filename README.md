# mysql-proxy-sh

AI한테 MySQL 접근권을 주고 싶은데 크레덴셜은 주기 싫을 때 쓰는 스크립트.

`.env`에 DB 접속 정보를 저장해두면, AI는 그 파일을 못 읽고 쿼리랑 결과만 주고받을 수 있음. 구조는 단순하게 shell script 하나임.

## 설치

mysql-client 필요함.

```bash
brew install mysql-client  # macOS
sudo apt install mysql-client  # Ubuntu
```

## 설정

```bash
# 대화형으로 추가
./add_env.sh <설정명>

# 또는 직접 파일 생성
# envs/ai-do-not-read-<설정명>.env
DB_HOST=your-host.rds.amazonaws.com
DB_PORT=3306
DB_USER=username
DB_PASSWORD=password
DB_NAME=database
```

## 사용법

```bash
# 기본
./mysql_query.sh "SHOW DATABASES;"

# DB 지정
./mysql_query.sh "SELECT * FROM users LIMIT 10;" mydb

# 설정 선택
./mysql_query.sh -c prod "SELECT count(*) FROM orders;" mydb
```

## 보안

`envs/*.env`는 `.gitignore`에 등록되어 있어서 커밋 안 됨. SSL 강제 적용.
