## History file configuration - From oh-my-zsh
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000

setopt extended_history       # record timestamps
setopt hist_ignore_dups       # ignore duplicated
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_expire_dups_first # delete dupes first when HISTSIZE is bigger than SAVEHIST
setopt hist_verify            # show commands with history before running it
setopt share_history          # share command history