const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);

function createSessionConfig() {
  const isProduction = process.env.NODE_ENV === 'production';
  const isVercel = process.env.VERCEL === '1';

  const baseConfig = {
    secret: process.env.SESSION_SECRET || 'kitanime-secret-key-change-in-production',
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: isProduction,
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000,
      sameSite: isProduction ? 'strict' : 'lax'
    },
    name: 'kitanime.sid'
  };

  const supabaseUrl = process.env.VITE_SUPABASE_URL;
  const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

  if (supabaseUrl && supabaseKey) {
    const supabaseProjectRef = supabaseUrl.match(/https:\/\/([^.]+)\.supabase\.co/)?.[1];
    const connectionString = `postgresql://postgres.${supabaseProjectRef}:${process.env.SUPABASE_DB_PASSWORD || ''}@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres`;

    try {
      baseConfig.store = new pgSession({
        conString: connectionString,
        tableName: 'sessions',
        createTableIfMissing: false,
        ttl: 24 * 60 * 60
      });

      console.log('Using PostgreSQL session store with Supabase');
    } catch (error) {
      console.error('Failed to initialize PostgreSQL session store:', error);
      console.log('Falling back to MemoryStore');
    }
  } else {
    console.log('Using MemoryStore for sessions');
  }

  return baseConfig;
}

module.exports = createSessionConfig;
