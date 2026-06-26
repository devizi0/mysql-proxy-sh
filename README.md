# mysql-proxy-sh

A simple shell script for giving AI agents MySQL access without exposing credentials.

You keep your DB credentials in a local `.env` file that the AI can't read. The AI just passes a SQL query to the script and gets back the results. That's it.

## Install

You need mysql-client.

```bash
brew install mysql-client        # macOS
sudo apt install mysql-client    # Ubuntu
```

## Setup

```bash
# interactive
./add_env.sh <name>

# or just create the file manually
# envs/ai-do-not-read-<name>.env
DB_HOST=your-host.rds.amazonaws.com
DB_PORT=3306
DB_USER=username
DB_PASSWORD=password
DB_NAME=database
```

## Usage

```bash
./mysql_query.sh "SHOW DATABASES;"

./mysql_query.sh "SELECT * FROM users LIMIT 10;" mydb

./mysql_query.sh -c prod "SELECT count(*) FROM orders;" mydb
```

## Security

`envs/*.env` is in `.gitignore` so credentials never get committed. SSL is enforced.
