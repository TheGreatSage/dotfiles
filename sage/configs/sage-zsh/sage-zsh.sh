if [ -z "${SAGE_ZSH_DIR}" ]; then
    return 0
fi

# Check for cache
if [ -z "${SAGE_ZSH_CACHE_DIR}" ]; then
    SAGE_ZSH_CACHE_DIR="${SAGE_ZSH_DIR}/cache"
fi

# Make sure it's writable
if [ ! -w "${SAGE_ZSH_CACHE_DIR}" ]; then 
    SAGE_ZSH_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/sage-zsh"
fi

# Load actual config files
for config_File in "${SAGE_ZSH_DIR}"/config/*.zsh; do 
    # shellcheck source=/dev/null
    . "${config_File}"
done

# Get rid of beeping
setopt nobeep

## Auto complete
autoload -Uz compinit
compinit


# Load the theme
find_theme() {
    local name=$1
    builtin test -f "${SAGE_ZSH_DIR}/themes/${name}.zsh-theme"
}

load_theme() {
    local name=$1
    if [ -f "${SAGE_ZSH_DIR}/themes/${name}.zsh-theme" ]; then
        . "${SAGE_ZSH_DIR}/themes/${name}.zsh-theme"
    else
        echo "[sage-zsh] theme '$name' not found!"
    fi
}

if [ -n "${SAGE_ZSH_THEME}" ]; then
    load_theme "${SAGE_ZSH_THEME}"
else
    load_theme "bureau"
fi