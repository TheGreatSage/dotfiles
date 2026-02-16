#!/usr/bin/env sh


ohmyzsh_install() {
    if [ -d "${HOME}/.config/oh-my-zsh" ]; then
        print_notice "There is a .oh-my-zsh directory, skipping install."
        return
    fi
    # Spawning a new shell so not worried about the return of this.
    # shellcheck disable=SC2312
    ZSH="${HOME}/.config/oh-my-zsh" sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

sagedot_chsh "zsh"
ohmyzsh_install