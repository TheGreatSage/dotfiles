
migrations_v1() {
    local _res
    _res="$(sqlite_get_version)"

    if [ "${_res}" != "1.0.0" ]; then
        return
    fi

    print_debug "[migration] 1.0.0"

    local sql="
    CREATE TABLE IF NOT EXISTS profiles (
        id INTEGER PRIMARY KEY,
        profile TEXT UNIQUE NOT NULL,
        installed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS backups (
        id INTEGER PRIMARY KEY,
        profile INTEGER NOT NULL,
        date TEXT UNIQUE NOT NULL,
        folder TEXT NOT NULL,
        FOREIGN KEY (profile) REFERENCES profiles(id)
    );
    CREATE TABLE IF NOT EXISTS backup_files (
        id INTEGER PRIMARY KEY,
        backup INTEGER NOT NULL,
        file TEXT NOT NULL,
        name TEXT NOT NULL,
        hash TEXT NOT NULL,
        FOREIGN KEY (backup) REFERENCES backups(id)
    );
    CREATE TABLE IF NOT EXISTS packages (
        id INTEGER PRIMARY KEY,
        profile INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (profile) REFERENCES profiles(id)
    );
    CREATE TABLE IF NOT EXISTS run_once (
        id INTEGER PRIMARY KEY,
        profile INTEGER NOT NULL,
        before INTEGER DEFAULT 1 NOT NULL,
        folder TEXT NOT NULL,
        file TEXT NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (profile) REFERENCES profiles(id)
    );
    CREATE TABLE IF NOT EXISTS run_onchange (
        id INTEGER PRIMARY KEY,
        profile INTEGER NOT NULL,
        before INTEGER DEFAULT 1 NOT NULL,
        folder TEXT NOT NULL,
        file TEXT NOT NULL,
        name TEXT NOT NULL,
        first_ran TEXT NOT NULL,
        last_ran TEXT NOT NULL,
        hash TEXT NOT NULL,
        FOREIGN KEY (profile) REFERENCES profiles(id)
    );  
    "
    sqlite_run "${sql}"
}

migrations_v1