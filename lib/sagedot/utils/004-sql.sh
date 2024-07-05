#!/usr/bin/env sh

#######################################
# Exit if sqlite is not available
#
# Outputs:
#   Exits if sqlite3 is not found
verify_sqlite() {
    if ! has sqlite3; then
        print_error "SQLite not installed!"
        exit 1
    fi
}

#######################################
# Create the needed tables for a sagedot file
#
# Globals:
#   SAGEDOT_FILE
sqlite_sagedot() {
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
    sqlite3 "${SAGEDOT_FILE}" "${sql}"
}

#######################################
# Run an sql statment against the sagedot file
#
# Arguments:
#   $1: sql statement
# Globals:
#   SAGEDOT_FILE
# Outputs:
#   Exits if arguments are wrong
#   Result of sqlite to stdout
sqlite_run() {
    local sql
    if [ "$#" -gt 0 ]; then
        sql="${1}"
    else
        log_error "[sqlite_run] Wrong arguments!"
        return
    fi
    sqlite3 "${SAGEDOT_FILE}" "${sql}"
}
