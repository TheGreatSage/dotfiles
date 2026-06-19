 
# Sage's Edit of oh-my-zsh Bureau Theme

# Changes:
# Some color configs
# Add Brackets
# Add Pipe
# Remove Node version
# Add switch for last commit time
# Add Project version - https://github.com/aifrim/aifrim.zsh-theme/

# Wants to Add:
# Python venv - Low priority as I'm not doing python right now

### Config
SAGE_THEME_GIT_COMMIT_TIME=false

# [user@host] The @ is part of Host
SAGE_THEME_USER_COLOR=white
SAGE_THEME_USER_BOLD=true
SAGE_THEME_HOST_COLOR=white
SAGE_THEME_HOST_BOLD=false
SAGE_THEME_ROOT_COLOR=red
SAGE_THEME_ROOT_BOLD=true

SAGE_THEME_USER_LIBERTY_COLOR="green"
SAGE_THEME_USER_LIBERTY="$"
SAGE_THEME_ROOT_LIBERTY_COLOR="red"
SAGE_THEME_ROOT_LIBERTY="#"

SAGE_THEME_PATH_COLOR=white
SAGE_THEME_PATH_BOLD=false

SAGE_THEME_DECOR_COLOR="blue"
SAGE_THEME_DECOR_BOLD=false

# PROJECT NAME / VERSION COLORS
SAGE_THEME_PROJECT_NAME_COLOR="cyan"
SAGE_THEME_PROJECT_NAME_BOLD=false
SAGE_THEME_PROJECT_AT_COLOR="cyan"
SAGE_THEME_PROJECT_AT_BOLD=false
SAGE_THEME_PROJECT_VERSION_COLOR="magenta"
SAGE_THEME_PROJECT_VERSION_BOLD=true

### Helpers

# params `color` `text` `bold`
wrap_color () {
  if [[ $3 = true ]]; then
    echo "%{$fg_bold[$1]%}$2%{$reset_color%}"
  else
    echo "%{$fg[$1]%}$2%{$reset_color%}"
  fi
}

# params `text`
create_decor () {
  wrap_color $SAGE_THEME_DECOR_COLOR $1 $SAGE_THEME_DECOR_BOLD
}

# params `text`
wrap_brackets () {
  echo "$_LBRACKET$1$_RBRACKET"
}

### Brackets & Pipes
_LBRACKET=`create_decor [`
_RBRACKET=`create_decor ]`
_TPIPE=`create_decor ┌─`
_BPIPE=`create_decor └─`

### NVM
# Unused, as I didn't like the version.
ZSH_THEME_NVM_PROMPT_PREFIX="%B⬡%b "
ZSH_THEME_NVM_PROMPT_SUFFIX=""

### Git [±master ▾●]

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[green]%}±%{$reset_color%}%{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_PREFIX="$_LBRACKET$ZSH_THEME_GIT_PROMPT_PREFIX"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$ZSH_THEME_GIT_PROMPT_SUFFIX$_RBRACKET"

ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[cyan]%}▴%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}▾%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg_bold[yellow]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_STASHED="(%{$fg_bold[blue]%}✹%{$reset_color%})"

bureau_git_info () {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

bureau_git_status () {
  local result gitstatus
  gitstatus="$(command git status --porcelain -b 2>/dev/null)"

  # check status of files
  local gitfiles="$(tail -n +2 <<< "$gitstatus")"
  if [[ -n "$gitfiles" ]]; then
    if [[ "$gitfiles" =~ $'(^|\n)[AMRD]. ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_STAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n).[MTD] ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)\\?\\? ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)UU ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNMERGED"
    fi
  else
    result+="$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  # check status of local repository
  local gitbranch="$(head -n 1 <<< "$gitstatus")"
  if [[ "$gitbranch" =~ '^## .*ahead' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if [[ "$gitbranch" =~ '^## .*behind' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi
  if [[ "$gitbranch" =~ '^## .*diverged' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_DIVERGED"
  fi

  # check if there are stashed changes
  if command git rev-parse --verify refs/stash &> /dev/null; then
    result+="$ZSH_THEME_GIT_PROMPT_STASHED"
  fi

  echo $result
}

bureau_git_prompt () {
  # ignore non git folders and hidden repos (adapted from lib/git.zsh)
  if ! command git rev-parse --git-dir &> /dev/null \
     || [[ "$(command git config --get oh-my-zsh.hide-info 2>/dev/null)" == 1 ]]; then
    return
  fi

  # check git information
  local gitinfo=$(bureau_git_info)
  if [[ -z "$gitinfo" ]]; then
    return
  fi

  # quote % in git information
  local output="${gitinfo:gs/%/%%}"

  # check git status
  local gitstatus=$(bureau_git_status)
  if [[ -n "$gitstatus" ]]; then
    output+=" $gitstatus"
  fi

  local out2="${ZSH_THEME_GIT_PROMPT_PREFIX}${output}"
  if [[ $SAGE_THEME_GIT_COMMIT_TIME = true ]]; then 
    out2="${out2} $(git_time_since_commit)"
  fi
  out2="${out2}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  echo "${out2}"
}

# I found this function in a few repos:
# https://github.com/amreshpro/zsh-theme
# https://github.com/consolemaverick/zsh2000/

# Colors vary depending on time lapsed.
ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT="%{$fg[green]%}"
ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM="%{$fg[yellow]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG="%{$fg[red]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL="%{$fg[cyan]%}"

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
git_time_since_commit () {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Only proceed if there is actually a commit.
        if last_commit=`git -c log.showSignature=false log --pretty=format:'%at' -1 2> /dev/null`; then
            now=`date +%s`
            seconds_since_last_commit=$((now-last_commit))

            # Totals
            MINUTES=$((seconds_since_last_commit / 60))
            HOURS=$((seconds_since_last_commit/3600))

            # Sub-hours and sub-minutes
            DAYS=$((seconds_since_last_commit / 86400))
            SUB_HOURS=$((HOURS % 24))
            SUB_MINUTES=$((MINUTES % 60))

            if [[ -n $(git status -s 2> /dev/null) ]]; then
                if [ "$MINUTES" -gt 30 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
                elif [ "$MINUTES" -gt 10 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
                else
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
                fi
            else
                COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
            fi

            if [ "$HOURS" -gt 24 ]; then
                echo "$COLOR${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m%{$reset_color%}"
            elif [ "$MINUTES" -gt 60 ]; then
                echo "$COLOR${HOURS}h${SUB_MINUTES}m%{$reset_color%}"
            else
                echo "$COLOR${MINUTES}m%{$reset_color%}"
            fi
        fi
    fi
}

# Found At:
# https://github.com/aifrim/aifrim.zsh-theme/
node_version () {
  if [ -f ./package.json ]; then
    local name=$(cat package.json | grep "name" -m1 | sed -r 's/\s?"name": |"|,|\ //g')
    local version=$(cat package.json | grep "version" -m1 | sed -r 's/\s?"version": |"|,|\ //g')
    local at=`wrap_color $SAGE_THEME_PROJECT_AT_COLOR @ $SAGE_THEME_PROJECT_AT_BOLD`

    if [ -z "$name" ]; then
      # There is no name in package.json - therefore, we will not echo anything
    else
      if [ -z "$version" ]; then
        version="0.0.1"
      fi
      name=`wrap_color $SAGE_THEME_PROJECT_NAME_COLOR $name $SAGE_THEME_PROJECT_NAME_BOLD`
      version=`wrap_color $SAGE_THEME_PROJECT_VERSION_COLOR $version $SAGE_THEME_PROJECT_VERSION_BOLD`

      local out=`wrap_brackets "$name$at$version"`
      echo " $out"
    fi
  fi
}

# Found At:
# https://github.com/aifrim/aifrim.zsh-theme/
rust_version () {
  if [ -f ./Cargo.toml ]; then
    local name=$(cat Cargo.toml | grep "name = " -m1 | sed -r 's/name = |"|,|\ //g')
    local version=$(cat Cargo.toml | grep "version = " -m1 | sed -r 's/version = |"|,|\ //g')
    local at=`wrap_color $SAGE_THEME_PROJECT_AT_COLOR @ $SAGE_THEME_PROJECT_AT_BOLD`

    name=`wrap_color $SAGE_THEME_PROJECT_NAME_COLOR $name $SAGE_THEME_PROJECT_NAME_BOLD`
    version=`wrap_color $SAGE_THEME_PROJECT_VERSION_COLOR $version $SAGE_THEME_PROJECT_VERSION_BOLD`

    local out=`wrap_brackets "$name$at$version"`
    echo " $out"
  fi
}

# Found At:
# https://github.com/aifrim/aifrim.zsh-theme/
go_version () {
  if [ -f ./go.mod ]; then
    local name=$(cat go.mod | grep "module " -m1 | sed -r 's/module |"|,|\ |\/v[0-9]*//g')
    local version=$(cat go.mod | grep "module " -m1 | grep "v[0-9]*" -o -m1)
    local at=`wrap_color $SAGE_THEME_PROJECT_AT_COLOR @ $SAGE_THEME_PROJECT_AT_BOLD`

    if [ -z "$version" ]; then
      version="v1"
    fi

    name=`wrap_color $SAGE_THEME_PROJECT_NAME_COLOR $name $SAGE_THEME_PROJECT_NAME_BOLD`
    version=`wrap_color $SAGE_THEME_PROJECT_VERSION_COLOR $version $SAGE_THEME_PROJECT_VERSION_BOLD`

    local out=`wrap_brackets "$name$at$version"`
    echo " $out"
  fi
}

_PATH=`wrap_color $SAGE_THEME_PATH_COLOR %~ $SAGE_THEME_PATH_BOLD`
_PATH=`wrap_brackets $_PATH`

if [[ $EUID -eq 0 ]]; then
  _USERNAME=`wrap_color $SAGE_THEME_ROOT_COLOR %n $SAGE_THEME_ROOT_BOLD`
  _LIBERTY=`wrap_color $SAGE_THEME_ROOT_LIBERTY_COLOR $SAGE_THEME_ROOT_LIBERTY`
else
  _USERNAME=`wrap_color $SAGE_THEME_USER_COLOR %n $SAGE_THEME_USER_BOLD`
  _LIBERTY=`wrap_color $SAGE_THEME_USER_LIBERTY_COLOR $SAGE_THEME_USER_LIBERTY`
fi

# Allow for chaning hostname color
_USERNAME+=`wrap_color $SAGE_THEME_HOST_COLOR @%m $SAGE_THEME_HOST_BOLD`

# Wrap in brackets
_USERNAME=`wrap_brackets $_USERNAME`

get_space () {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=$(( COLUMNS - LENGTH - ${ZLE_RPROMPT_INDENT:-1} ))

  (( SPACES > 0 )) || return
  printf ' %.0s' {1..$SPACES}
}

# Add the top pipe
_1LEFT="$_TPIPE $_USERNAME $_PATH"

_1LEFT+="$(node_version)"
_1LEFT+="$(go_version)"
_1LEFT+="$(rust_version)"

# Wrap time in brackets
_1RIGHT=`wrap_brackets %\*`

bureau_precmd () {
  _1SPACES=`get_space $_1LEFT $_1RIGHT`
  print
  print -rP "$_1LEFT$_1SPACES$_1RIGHT"
}

setopt prompt_subst
# Add the buttom pipe
PROMPT='$_BPIPE $_LIBERTY '
RPROMPT='$(bureau_git_prompt)'

autoload -U add-zsh-hook
add-zsh-hook precmd bureau_precmd
