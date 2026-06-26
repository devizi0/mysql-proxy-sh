#!/usr/bin/env zsh
# 사용법: ./mysql_query.sh [-c 설정명] "SQL 쿼리" [데이터베이스명]
#   -c 설정명  envs/<설정명>.env 사용 (기본값: default)
# 예시:
#   ./mysql_query.sh "SHOW DATABASES;"
#   ./mysql_query.sh -c prod "SELECT * FROM tbl_esim_orders LIMIT 5;" prod_zerotravel_esim
#   ./mysql_query.sh -c stag "SHOW TABLES;" stag_zerotravel

SCRIPT_DIR="${0:A:h}"
MYSQL="$(command -v mysql 2>/dev/null || echo /opt/homebrew/opt/mysql-client/bin/mysql)"
CONFIG="default"

# -c 옵션 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

ENV_FILE="$SCRIPT_DIR/envs/ai-do-not-read-${CONFIG}.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] 설정 파일이 없습니다: ai-do-not-read-${CONFIG}.env" >&2
  echo "사용 가능한 설정:" >&2
  ls "$SCRIPT_DIR/envs/" 2>/dev/null | sed 's/ai-do-not-read-//' | sed 's/\.env$//' | sed 's/^/  /' >&2
  exit 1
fi

chmod 600 "$ENV_FILE"

# .env 로드
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  export "$key"="$value"
done < "$ENV_FILE"

if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "[ERROR] $ENV_FILE 에 DB_HOST, DB_USER, DB_PASSWORD를 설정하세요." >&2
  exit 1
fi

SQL="${1:-}"
DB="${2:-${DB_NAME:-}}"

if [[ -z "$SQL" ]]; then
  echo "[ERROR] 쿼리를 인수로 전달하세요." >&2
  echo "사용법: $0 [-c 설정명] \"SQL\" [데이터베이스명]" >&2
  echo "" >&2
  echo "사용 가능한 설정:" >&2
  ls "$SCRIPT_DIR/envs/" 2>/dev/null | sed 's/\.env$//' | sed 's/^/  /' >&2
  exit 1
fi

ARGS=(
  -h "$DB_HOST"
  -P "${DB_PORT:-3306}"
  -u "$DB_USER"
  "-p${DB_PASSWORD}"
  --ssl-mode=REQUIRED
  --default-character-set=utf8mb4
  -e "$SQL"
)

if [[ -n "$DB" ]]; then
  ARGS+=("$DB")
fi

exec "$MYSQL" "${ARGS[@]}"
