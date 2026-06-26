# mysql-proxy-sh

A shell-based MySQL proxy that lets AI agents execute queries **without ever seeing credentials**.

## Concept

AI agents (like Claude) need database access to be useful — but handing them raw credentials is a security risk. This script acts as a thin proxy: the agent calls the script with a SQL query, the script loads credentials from a local `.env` file that the AI cannot read, and only the query result is returned.

```
AI Agent  -->  mysql_query.sh  -->  .env (AI cannot read)  -->  MySQL DB
              (only sees SQL          (credentials stay
               and results)            on your machine)
```

## Usage

```bash
# Default config (envs/ai-do-not-read-default.env)
~/agent/mysql-proxy/mysql_query.sh "SHOW DATABASES;"

# Specific config
~/agent/mysql-proxy/mysql_query.sh -c <config-name> "SQL" [database]
```

## Examples

```bash
# List databases
~/agent/mysql-proxy/mysql_query.sh "SHOW DATABASES;"

# List tables
~/agent/mysql-proxy/mysql_query.sh "SHOW TABLES;" mydb

# Query data
~/agent/mysql-proxy/mysql_query.sh "SELECT * FROM users LIMIT 10;" mydb

# Use a different config
~/agent/mysql-proxy/mysql_query.sh -c prod "SELECT count(*) FROM orders;" mydb
```

## Setup

### 1. Install mysql-client

```bash
# macOS
brew install mysql-client

# Ubuntu/Debian
sudo apt install mysql-client
```

### 2. Add credentials

```bash
# Interactive setup
./add_env.sh <config-name>

# Or manually create envs/ai-do-not-read-<config-name>.env
DB_HOST=your-host.rds.amazonaws.com
DB_PORT=3306
DB_USER=username
DB_PASSWORD=password
DB_NAME=database
```

### 3. Run

```bash
chmod +x mysql_query.sh
./mysql_query.sh "SELECT 1;"
```

## File Structure

```
mysql-proxy/
├── envs/
│   ├── ai-do-not-read-default.env    # credentials (git ignored)
│   └── ai-do-not-read-<name>.env     # additional configs
├── mysql_query.sh                     # main script
├── add_env.sh                         # interactive credential setup
├── .env.example                       # example env format
└── .gitignore                         # excludes envs/*.env
```

## Security

- `envs/*.env` files are **git ignored** — credentials never leave your machine
- File permissions are set to `600` (owner read/write only) automatically
- SSL is enforced (`--ssl-mode=REQUIRED`)
- The AI only sees SQL queries and their results — never credentials

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-c <name>` | Use `envs/ai-do-not-read-<name>.env` | `default` |
| `"SQL"` | SQL query to execute (required) | - |
| `[database]` | Database to connect to | value in `.env` |

## Requirements

- zsh
- mysql-client (auto-detected via `command -v mysql`)
