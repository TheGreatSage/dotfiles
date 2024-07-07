migrations_v1_1() {
    local _res
    _res="$(sqlite_get_version)"

    if [ "${_res}" != "1.0.0" ]; then
        return
    fi

    print_debug "[migration] 1.1.0"

    local sql="
    CREATE TABLE IF NOT EXISTS sagedot (
        id INTEGER PRIMARY KEY,
        key TEXT UNIQUE NOT NULL,
        value TEXT
    );
    "
    _res="$(sqlite_run "${sql}")"

    sql="
    INSERT INTO sagedot (key, value)
    VALUES ('version', '1.1.0');
    "
    _res="$(sqlite_run "${sql}")"

    _res="$(sqlite_get_version)"
    if [ -z "${_res}" ] || [ "${_res}" != "1.1.0" ]; then
        print_error "Migration to 1.1.0 failed!" 
        exit 1
    fi
}

migrations_v1_1