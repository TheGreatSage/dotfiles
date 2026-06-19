# https://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4

setopt always_to_end    # move cursor to end of word on completion
setopt auto_menu        # Use the menu on multiple requests
setopt complete_in_word # Something with cursor

unsetopt menu_complete  # do not auto select menu entry
unsetopt flowcontrol    # Not sure

# Z-Style for comletions

# Complete . and .. dirs
zstyle ':completion:*' special-dirs true

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes

if [ ! -d "${SAGE_ZSH_CACHE_DIR}/completions" ]; then
    mkdir -p "${SAGE_ZSH_CACHE_DIR}/completions"
fi
zstyle ':completion:*' cache-path ${SAGE_ZSH_CACHE_DIR}/completions

# Show completion stuff as menu
zstyle ':completion:*' menu select

# Order of matchers matters: m should come before r, which should come before l.
# Otherwise, the results are not as expected.
local lower_to_upper='m:{[:lower:]-}={[:upper:]_}'
local any_before_dot='r:|[.]=**'
local any_before_any='r:|?=**'
local nonseparators_after_any_before_separator='r:?||[-_ \]=*'
local any_before_word='l:|=*'
local separator_after_any='l:?|=[-_ \]'
zstyle ':completion:*' matcher-list \
    "$lower_to_upper $any_before_dot"
zstyle ':completion:*-fuzzy:*' matcher-list \
    "$lower_to_upper $any_before_dot $any_before_word" \
    "+$nonseparators_after_any_before_separator $separator_after_any" \
    "$lower_to_upper $any_before_any"