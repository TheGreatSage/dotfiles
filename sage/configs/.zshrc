# Most of the config got moved to here

SAGE_ZSH_DIR=${SAGE_ZSH_DIR:="$HOME/.config/sage-zsh"}

if [ -d "$SAGE_ZSH_DIR" ]; then
    source $SAGE_ZSH_DIR/sage-zsh.sh
else
    echo "Could not find sage-zsh!"
    echo "Only setting ENV Configuration"
fi

# =======================================================
# Personal ENV Configuration
# This might change for non-sages
# =======================================================

# Forgot what this is for, but I've had it for a long time.
export GPG_TTY=$(tty)

# NVM loading
# TODO: Check if this adds startup time 
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use           # Loads NVM on use
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Docker
# TODO: Maybe do a check to see if docker is installed?
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# GO
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"

# ProtonUp-Qt
if [ -d "$HOME/stl/prefix" ]; then export PATH="$PATH:$HOME/stl/prefix"; fi

# Vulkan SDK. I don't like this global so not actually using.
# if [ -d "$HOME/code/vulkan/sdk" ]; then source "$HOME/code/vulkan/sdk/setup-env.sh"; fi