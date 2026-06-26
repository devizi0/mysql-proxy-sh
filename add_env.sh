#!/usr/bin/env zsh
# 사용법: ~/agent/mysql-proxy/add_env.sh <설정명>
# 예시:  ~/agent/mysql-proxy/add_env.sh prod

SCRIPT_DIR="${0:A:h}"

if [[ -z "$1" ]]; then
  echo "[ERROR] 설정명을 입력하세요." >&2
  echo "사용법: $0 <설정명>" >&2
  exit 1
fi

CONFIG="$1"
ENV_FILE="$SCRIPT_DIR/envs/ai-do-not-read-${CONFIG}.env"

if [[ -f "$ENV_FILE" ]]; then
  echo "[ERROR] 이미 존재합니다: ai-do-not-read-${CONFIG}.env" >&2
  exit 1
fi

echo -n "DB_HOST: "; read DB_HOST
echo -n "DB_PORT (기본 3306): "; read DB_PORT
echo -n "DB_USER: "; read DB_USER
echo -n "DB_PASSWORD: "; read -s DB_PASSWORD; echo

cat > "$ENV_FILE" <<EOF
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF

chmod 600 "$ENV_FILE"
echo "[완료] ai-do-not-read-${CONFIG}.env 생성됨"
echo "사용: ~/agent/mysql-proxy/mysql_query.sh -c ${CONFIG} \"SQL\" [DB명]"
