const mysql = require('mysql2');
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
  console.error('[ERROR] .env 파일이 없습니다.');
  process.exit(1);
}

const env = fs.readFileSync(envPath, 'utf8')
  .split('\n')
  .filter(l => l && !l.startsWith('#'))
  .reduce((acc, l) => {
    const [k, ...v] = l.split('=');
    if (k) acc[k.trim()] = v.join('=').trim();
    return acc;
  }, {});

const PROXY_PORT = parseInt(env.PROXY_PORT || '3307');
const dbConfig = {
  host:     env.DB_HOST,
  port:     parseInt(env.DB_PORT || '3306'),
  user:     env.DB_USER,
  password: env.DB_PASSWORD,
  multipleStatements: true,
  ssl: { rejectUnauthorized: false },
};

if (!dbConfig.host || !dbConfig.user || !dbConfig.password) {
  console.error('[ERROR] DB_HOST, DB_USER, DB_PASSWORD를 .env에 설정하세요.');
  process.exit(1);
}

let connCount = 0;

const server = mysql.createServer((conn) => {
  const id = ++connCount;
  console.log(`[${id}] 클라이언트 연결됨`);

  let db = null;

  conn.serverHandshake({
    protocolVersion: 10,
    serverVersion: '8.0.32',
    connectionId: id,
    statusFlags: 2,
    characterSet: 33,
    capabilityFlags: 0xffffff,
    authCallback: (handshakeInfo, cb) => {
      const clientDB = handshakeInfo.database;
      const cfg = Object.assign({}, dbConfig);
      if (clientDB) cfg.database = clientDB;

      console.log(`[${id}] 인증 — user: ${handshakeInfo.user}, db: ${clientDB || '(없음)'}`);

      db = mysql.createConnection(cfg);
      db.connect((err) => {
        if (err) {
          console.error(`[${id}] DB 연결 실패: ${err.message}`);
          cb(err);
        } else {
          console.log(`[${id}] DB 연결 성공`);
          cb(null);
        }
      });
    },
  });

  conn.on('query', (sql) => {
    console.log(`[${id}] 쿼리: ${sql.slice(0, 200)}`);
    if (!db) {
      conn.writeError({ message: 'DB에 연결되지 않았습니다.' });
      conn._resetSequenceId();
      return;
    }
    db.query(sql, (err, results, fields) => {
      if (err) {
        conn.writeError({ code: err.errno || 1064, message: err.sqlMessage || err.message });
      } else if (!fields) {
        conn.writeOk({ affectedRows: results.affectedRows || 0, insertId: results.insertId || 0 });
      } else {
        conn.writeTextResult(results, fields);
      }
      conn._resetSequenceId();
    });
  });

  conn.on('init_db', (dbName) => {
    console.log(`[${id}] USE ${dbName}`);
    if (!db) {
      conn.writeError({ message: 'DB 연결 없음' });
      conn._resetSequenceId();
      return;
    }
    db.query(`USE \`${dbName}\``, (err) => {
      if (err) conn.writeError({ code: err.errno, message: err.sqlMessage || err.message });
      else conn.writeOk();
      conn._resetSequenceId();
    });
  });

  conn.on('ping', () => {
    conn.writeOk();
    conn._resetSequenceId();
  });

  conn.on('quit', () => {
    if (db) db.end();
    conn.stream.end();
  });

  conn.on('error', (err) => {
    console.error(`[${id}] 에러: ${err.message}`);
    if (db) db.end();
  });

  conn.on('end', () => {
    console.log(`[${id}] 연결 종료`);
    if (db) db.end();
  });
});

server.on('error', (err) => {
  console.error(`[서버 에러] ${err.message}`);
  process.exit(1);
});

server.listen(PROXY_PORT, '127.0.0.1', () => {
  console.log(`[MySQL Proxy] 시작됨`);
  console.log(`  로컬:  127.0.0.1:${PROXY_PORT}`);
  console.log(`  대상:  ${dbConfig.host}:${dbConfig.port}`);
  console.log(`  접속:  mysql -h 127.0.0.1 -P ${PROXY_PORT} --ssl-mode=DISABLED`);
  console.log('  (비밀번호 없이 접속 가능)');
});

process.on('SIGINT', () => {
  server.close(() => process.exit(0));
});
