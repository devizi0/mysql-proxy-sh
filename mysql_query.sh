#!/usr/bin/env zsh
# 사용법: ./mysql_query.sh [-c 설정명] "SQL 쿼리" [데이터베이스명]
#         ./mysql_query.sh add <설정명>
#         ./mysql_query.sh remove <설정명>
#         ./mysql_query.sh list

SCRIPT_DIR="${0:A:h}"
MYSQL="$(command -v mysql 2>/dev/null || echo /opt/homebrew/opt/mysql-client/bin/mysql)"
CONFIG="default"

if [[ $# -eq 0 ]]; then
  echo "Usage:"
  echo "  $0 [-c <config>] \"SQL\" [database]"
  echo ""
  echo "Subcommands:"
  echo "  $0 add <config>     — add a new DB config (interactive)"
  echo "  $0 remove <config>  — remove a DB config"
  echo "  $0 list             — list available configs"
  echo ""
  echo "Examples:"
  echo "  $0 \"SHOW DATABASES;\""
  echo "  $0 \"SELECT * FROM users LIMIT 10;\" mydb"
  echo "  $0 -c prod \"SELECT count(*) FROM orders;\" mydb"
  exit 0
fi

# 서브커맨드 처리
case "$1" in
  add)
    CONFIG="$2"
    if [[ -z "$CONFIG" ]]; then
      echo "[ERROR] 설정명을 입력하세요. 사용법: $0 add <설정명>" >&2
      exit 1
    fi
    ENV_FILE="$SCRIPT_DIR/envs/ai-do-not-read-${CONFIG}.env"
    mkdir -p "$SCRIPT_DIR/envs"
    if [[ -f "$ENV_FILE" ]]; then
      echo "[ERROR] 이미 존재합니다: ai-do-not-read-${CONFIG}.env" >&2
      exit 1
    fi
    echo -n "DB_HOST: "; read DB_HOST
    echo -n "DB_PORT (default 3306): "; read DB_PORT
    echo -n "DB_USER: "; read DB_USER
    echo -n "DB_PASSWORD: "; read -s DB_PASSWORD; echo
    echo -n "DB_NAME (optional, enter to skip): "; read DB_NAME
    cat > "$ENV_FILE" <<EOF
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF
    [[ -n "$DB_NAME" ]] && echo "DB_NAME=${DB_NAME}" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "[done] created: ai-do-not-read-${CONFIG}.env"
    exit 0
    ;;
  remove)
    CONFIG="$2"
    if [[ -z "$CONFIG" ]]; then
      echo "[ERROR] 설정명을 입력하세요. 사용법: $0 remove <설정명>" >&2
      exit 1
    fi
    ENV_FILE="$SCRIPT_DIR/envs/ai-do-not-read-${CONFIG}.env"
    if [[ ! -f "$ENV_FILE" ]]; then
      echo "[ERROR] 존재하지 않습니다: ai-do-not-read-${CONFIG}.env" >&2
      exit 1
    fi
    rm "$ENV_FILE"
    echo "[done] removed: ai-do-not-read-${CONFIG}.env"
    exit 0
    ;;
  list)
    echo "available configs:"
    ls "$SCRIPT_DIR/envs/" 2>/dev/null | sed 's/ai-do-not-read-//' | sed 's/\.env$//' | sed 's/^/  /'
    exit 0
    ;;
esac

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
  echo "Usage:"
  echo "  $0 [-c <config>] \"SQL\" [database]"
  echo ""
  echo "Subcommands:"
  echo "  $0 add <config>     — add a new DB config (interactive)"
  echo "  $0 remove <config>  — remove a DB config"
  echo "  $0 list             — list available configs"
  echo ""
  echo "Examples:"
  echo "  $0 \"SHOW DATABASES;\""
  echo "  $0 \"SELECT * FROM users LIMIT 10;\" mydb"
  echo "  $0 -c prod \"SELECT count(*) FROM orders;\" mydb"
  exit 0
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
