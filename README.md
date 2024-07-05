# Dotfiles

## Overview
This is a repository to backup and install all of Sage's dotfiles. Using a custom shell script called [sagedot](#sagedot) to copy files.

## Supported OS
 - Arch Linux
 - Alpine
 - Debian

## Install
1. Download
```sh
git clone https://github.com/TheGreatSage/dotfiles
cd dotfiles
```
2. Install

**NOTICE: A sudo/doas capable user is required to run [sagedot](#sagedot). Not root. See [requirements](#requirements)**

**WARNING: [sagedot](#sagedot) installs the package `sqlite` in order to function.**

**WARNING: Please read through [Sage's Profile](#profile-sage) to see what it installs**

```sh
./sagedot install sage
```
3. Follow the prompts

[sagedot](#sagedot) does several things that require the use of `sudo` or in the case of alpine `doas`. So it will promt you to put in your password when needed for those commands.

4. Restart your shell.

The [sage profile](#profile-sage) installs zsh and changes your shell to it (You where probably prompted to make those changes). So restarting you're shell is needed to take effect.

5. Enjoy!

## Profile: Sage
Things included in my profile. I'm not a config heavy person so there is only a few things.

I'll try my best to keep this readme updated, but if you think it's doing other things, just poke around the `sage` folder and you can double check. 

1. **Packages**

See the file `sage/packages.list` for the installed packages.

2. **Kitty**

`~/.config/kitty/`

Just a simple ever work in progress styling for the kitty terminal.

3. **zsh**

`~/.zshrc`

My zsh config is pretty simple and relies on [oh my zsh](https://ohmyz.sh/). I include the custom `bureau` theme that I currently use.

4. **bash**

`~/.bashrc`
I include my old bash `.bashrc` file just in case I decide to make any changes there.

# sagedot
[sagedot](#sagedot) is the custom shell program I wrote to manage copying the config to the correct place.

## Requirements
It requires a `sudo/doas` capable user to install necessary packages, and packages included in profiles.

`sqlite` is required for [sagedot](#sagedot) to remember state. It is installed when you install a profile for the first time.

## Warnings
This project is mostly for personal use so it's not considered **battle-hardened** or **production ready**. I'll try not to push breaking changes but I have no plans to implement database migrations so any change to the database is probably a **breaking change**.

When installing a profile [sagedot](#sagedot) installs the `sqlite` package. It also creates a file `sagedot.sb` in the root of the install folder see the [database](#database) section on why that is.

**Alpine** updates the `/etc/repositories` file to the `edge` branch. The way it does this is very destructive and may change at some point. I'll probably gate this behind a yes/no question. See [todo](#todo). Also [alpine notes](#alpine-notes) on how to disable this.

It may break, it may get changed, or it may work how it was designed. You have been warned!

If you intend to use this for your own dotfiles you probably want to read through the whole readme before double checking the code.

## Usage
```
./sagedot [OPTIONS] -i|--install|install profile [profile...]
./sagedot [OPTIONS] -h|--help|help
./sagedot [OPTIONS] -c|--commands|commands
./sagedot [OPTIONS] --version|version

OPTIONS:
    -v | verbose) Increase the log level to the highest
    -d | debug) Run in debug mode (for development)
```

## Why make sagedot
I wanted a simple script to copy flat files into the correct locations. When looking around most seemed to use symlinks and [chezmoi](#chezmoi) just didn't click for me. After finding some [other projects](#credits) that seemed good I felt I should just make it over a few days. 

I really enjoyed working on this and I will try and improve it in between other projects. The first iteration of [sagedot](#sagedot) was complete **2024-07-04**.

- [2024-07-04] The first iteration of sagedot is complete. Currently it *just works*. There is plenty that could be added. Yet, it does what it was designed to do, and not much else.

## How it was built
This project was coded on an Arch Linux machine, using [VSCodium](https://vscodium.com/) as a text editor. I made heavy use of [shellcheck](https://www.shellcheck.net/). I only considered it working when it successfully worked on an Arch Linux, Debain, and Alpine VM. 

I did my best to keep things organized and documented. There is still plenty I will probably work on in the future. Check out [todo](#todo) for my next plans.

## Design Goals
Things that I thought where required for [sagedot](#sagedot).
- Support for Alpine, Arch, and Debian linux distributions.
- Do not require `bash`, see [Portability](#portability)
- Easy config install
- Flat files, not symlinks
- Profiles, e.g multiple sets of config
- Install packages
- Run other scripts
- Backup replaced files
- Use a database somewhere

See [todo](#todo) for things I might add at some point.

## Non-goals
Things I decided that I didn't need functionality for.
- Files outside of `$HOME`.
- Removal of changed files.
- Root user install

### Decisions around `$HOME`
I decided I only want to support the `$HOME` directory. Due to the setup with profiles and how I sructured the config file the current way makes it difficult to support more than the `$HOME` directory. It may be something that I come back to if I ever need to bring along files that don't live in `$HOME`.

### Removal of changed files
While working on this I decided I only want [sagedot](#sagedot) to push changes. Never remove them. Because I don't store changed files, [sagedot](#sagedot) would only know about files that are currently in the configs folder of a profile. 

### Root User
I could have made [sagedot](#sagedot) support the root user and install base packages and do other install setup but decided that I should limit this program to a user that has `sudo` privilage.

## sagedot Project Structure
The [sagedot](#sagedot) library lives in the `./lib/sagedot` folder. With the frontend `sagedot` file that is the main entry point.
```
~/dotfiles
├─┬─ lib        # I nest sagedot inside the lib folder, just because.
│ └─┬─ sagedot  # Everything sagedot related lives here
│   ├─── alpine # Alpine specic setup scripts
│   ├─── logs   # The logs folder gets created after being ran
│   ├─── setup  # Anything that has an actual effect goes here, e.g initilization
│   └─── utils  # The main library of sagedot lives here
├── profile     # A profile folder lives on the main level
├── profile2... # Any other profile folders live here too
├── sagedot     # The sagedot entry script
└── sagedot.db  # The database sagedot creates
```
The [sagedot](#sagedot) library gets sourced in the `sagedot` file using globbing. Which is why I use the `###-*.sh` file scheme so they get loaded in a predictable mannger.

## Order of Operations
The order a [sagedot](#sagedot) runs is simple:

1. `sagedot` Parses the passed arguments
1. `lib/sagedot/utils/` Is loaded in order.
1. `lib/sagedot/setup/` This folder and the following are only loaded when an install takes place.
1. `lib/sagedot/alpine/` gets loaded after `001-distro.sh` from setup if on alpine. Note: this can be destructive. See [alpine notes](#alpine-notes).
1. `profile/*.list` files are processed and packages are installed.
2. `profile/scripts/before/` scripts are checked and ran based on type.
3. `profile/configs/` config files are copied over.
4. `profile/home/` config files are copied over.
5. `profile/scripts/after/` scripts are checked and ran based on type.

## Profiles
[sagedot](#sagedot) works based on profiles. Which means the root install of [sagedot](#sagedot) contains a profile folder (e.g sage). When running [sagedot](#sagedot) install it will check for the following files/folders:
- `profile/configs/` - see the [config folder](#folder-configs) section for how this works.
- `profile/home/`    - see the [home folder](#folder-home) section for how this works.
- `profile/scripts/` - see the [scripts folder](#folder-scripts) section for how this works.
- `profile/*.list`   - see the [package installs](#package-installs) section for how this works.

During a profile install a [sagedot.db](#database) file if it doesn't exist will remember what packages and scripts have been ran from this profile.

As of writing this documentation, [sagedot](#sagedot) does not support uninstalling a profile, only installing it. See [non-goals](#non-goals).

## Folder: Configs
A profile with a folder named `configs` will be treated as the `$HOME`/`~` directory. With a slight difference. Any **folder** will be sent to `~/.config/` as is. Any **file** will be sent to `~/` as is. See [non-goals](#non-goals) on why I don't support other locations.

Files will always be copied over, if an file with different content exists there then it will be moved to a [backups folder](#backups).

## Folder: Home
A profile with a folder named `home` will be treated as the `$HOME` directory.

This was originally added because oh-my-zsh creates its default folder in the home directory and I forgot it did that so I added support for a folder to just be copied over as is. Though I ened up just changing the default install location for oh-my-zsh also anyways.

## Folder: Scripts
Note: I don't recommend using scripts as I probably did this in the worst way possible. At somepoint I will probably change how they work.

The scripts folder does nothing by itself. You have to create `always`, `change`, `once` folders inside to dictate how often they run. Defaultly scripts run **before** the config files are copied over. To have more control on how they run create a `before` or `after` folder and place those folders in there. Scripts always run in alphabetical order. Scripts are **only** `*.sh` files.

- Scripts in the `always` folder: Run everytime you install/update a profile.
- Scripts in the `change` or `onchange` folder: Run when their content have changed since the last time they where ran.
- Scripts in the `once` folder: Run only the first time they are found, so renaming them will cause them to run again.
- A `before` folder: Acts like the default `scripts` folder, running content inside before the config files are copied over. Requires scripts to be in `always`, `change`, or `once` folders.
- A `after` folder: Will run after config files have been copied over. Requires scripts to be in `always`, `change` or `once` folders. 

I have done *very* little testing on the viability of running scripts. So here are some notes.
- I call scripts by sourcing them. i.e `source /script/` so they have full access to the [sagedot](#sagedot) utils, for better or worse.
- Consequently if your script exits then it will exit the installer.
- I'm pretty sure that also means you will be stuck using a sh shell

Running `once` or `onchange` scripts make use of the [sagedot.db](#database) file to remember their state.

## Package Installs
Any `*.list` file found in a profile will be parsed as packages to be installed. Using [kaixinguo360](#kaixinguo360)'s style of lists. Which means every package needs to be on it's own line. It also includes a options for selectivly installing packages.
- `package` - A normal package
- `@distro:package` - A distro specific package.
- `@!distro:package` - Any distro that does not match.
- `@manager:package` - A specific package manager only.
- `@!manager:package` - Any package manager that does not match.
- `# comment` - This line is removed.

These rules are very simple so I recommend only using the `@distro` rule. I found that making heavy use of the `@!not` rules was just asking for trouble.

The supported distros are: `arch`, `alpine`, `debian`.

The supported package managers are: `apt`, `apk`, `yay`, `pacman`

Because I support two different package managers for `arch`, `yay` and `pacman` I recomment using the `@arch` tag instead of on of those because the rules consider them seperate things.

## Backups
One of the [goals](#design-goals) of this project was to back up files. Because I'm using flat files I decided that I would like them to be backed up if there are any changes. Now I'm not sure my implementation is the best.

Every file that gets backed-up it gets placed in a folder inside the profile under `backups` followed by the date it was ran e.g `backups/2024-07-02T222744/`. It is also tracked in the [sagedot.db](#database) file.

The backups folder is structured like the `$HOME` directory to easily tell what files go where.

- [2024-07-03] There is currently no way to automatically restore a backup. See [todo](#todo).
- [2024-07-03] There is currently no way to auto list files that where backed-up. See [todo](#todo).

## Database
Why does [sagedot](#sagedot) require `sqlite`? Why use a database at all?

The answer to those questions is mostly, because I wanted to. I wanted to store some state and didn't want to handle parsing a file so thought it would be fun to include sqlite and call it from my scripts (It was).

What does it do?
- Tracking what profiles have been installed. (Not very well)
- Tracking what packages get install per profile.
- Tracking what files have been backed up.
- Tracking scripts that `run once` or `run on change`

For more insight check the `lib/sagedot/utils/004-sql.sh` file to see the full database.

## Limitations
This was written using the en_US.UTF-8 locale setting, so I'm sure find breaks on folders/files not UTF-8 compatible. 

Similarly, profiles can only be alpha numeric plus underscores and dashs. That however is a simple regex in `005-profile.sh` and could be hacked around pretty easily.

The difficulty with the various uses of `find` are (to me) much harder to work around when acounting for locales.

The use of `find` also disallows filenames/folders with `\n` in their names. They are just skipped.

This uses the `set -e` flag for the project so any command that fails will probably just crash the program. That is intentional.

## TODO
Things that I would like to add at some point but are not required by the [design goals](#design-goals).
- Dry run
- Update all installed profiles
- Restore backups
- List files from backups
- List packages installed
- Rework script handling to be better
- Ask before doing things - The **alpine** repository check should really require consent.
- Look into unit tests
- Look into templates - I don't personally need them but a lot of dotfile projects make use of them, so adding that in the future might be something I work on.
- Standardize all variable names
- Clean up code style to be even more consistent
- Make log/output messages more consistent

## Portability
This has been tested on Alpine, Arch Linux, and Debian virtual machines. Only a Arch Linux has been tested on a physical machine.

### POSIX Compliance
Nope. 

Here are things I know break compliance:
- Heavy use of the `local` keyword
- Use of the `mktemp` utility.
- Probably other things

The primary target for this was Alpine, Arch, and Debian so strict POSIX sh compliance is technically not needed. However, I tried my best by removing easy things that are not compliant. This project was written using `ShellCheck` with `ash` set to the default shell. I occasionally switch to `sh` to see what warnings show up.

### Other Compliance:
I read that `find type -f` may not be portable and I use that in a few spots. It's technically POSIX compliant but it was an offhand comment and I couldn't find more info on it so just noting it here.

`mktemp` seems might have problems with portability. I'm not sure on it's overall standard `mktemp` isn't POSIX as far as I'm aware.

### MacOS Compliance:
I'm including this section just note down things that I find that probably don't work on macOS. I have no intention of supporting macOS, as I don't want to buy a mac. However, if someone wishes to get this working with macOS be my guest.

- `mktemp` Might behave differently on macOS. It's only found in the main `sagedot` file.
- `realpath` I saw on a google search that `realpath` needs to be installed with the `coreutils` package. It is used in a few spots in the code. Notably in the main `sagedot` file for setting the working directory.

I'm probably missing some other things but this is what came up while writing this project. I would be interested in knowing other things that I make use of that break compatibility. 

### Debian Notes:
Debians `sqlite` package is `sqlite3` so instead of making a special folder for debain like Alpine has. The script `010-initialize.sh` makes use of the `@!debian:` and `@debian` tags when doing it's check for sqlite.

### Alpine Notes:
Alpine is the special case beacuse I wanted to make sure I had access to all the repositories on the edge branch. That means it changes the /etc/repositories file to a standard one that includes `main`, `community`, and `testing` edge branchs. If you don't want that behavior just comment the `verify_repository` line.

### Arch Notes:
I coded this on my daily machine that already had the configs in place then tested on a arch VM to make sure it still worked. I personally use the `yay` AUR helper which is why it is included in the package managers. It wouldn't be that hard to add a different one if they work in a similar way.

### Adding a distro:
To add support for a distro requires a little bit of editing. The `001-environment.sh` file in the `lib/sagedot/utils/` is where most of the work is done. Specifically: `which_distro`, `which_pmg`, `check_install` and `is_installed` make use of the package manager and distro.

If the distro requires specific setup like [alpine](#alpine-notes) then just copy how **alpine** does it. Create a folder with the setup needed, and load it from `001-distro.sh`.

If your distro does not use `systmctl` or `rc-service/rc-update` and you wish to make use of the `service_*` functions then you will have to change the `service_manager` function in `011-service.sh`.

If your distro uses a different `sudo` equivalent then editing the `verify_sudo` and `which_sudo` functions in `001-environment.sh` will also be needed. Note: `which_sudo` gets called in several places so making sure it is compatible is paramount.

## Credits
I did not do everything from scratch. I took heavy insparation and some code from the following projects.

### bashbot
[bashbot](https://github.com/bashdot/bashdot/) is where I got some the insaration to use profiles, so some of the profile code is lifted straight from them. `bashbot` uses symlinks which I decided not to use, but if you're after a tool to create symlinks with profile support, `bashbot` seems like a nice simple tool.

MIT Licenced

### kaixinguo360
[kaixinguo360](https://github.com/kaixinguo360/dotfiles/)'s dotfiles tool was huge in coding this project. I really liked how he structured it so I copied that style. It has made organizing my code much better. In addition I also use several of the helper funcitions that he wrote.

Stuff straight from him:
- packages
- lists
- source bundling
- several helper functions

Anyways, his tool was the most used and referenced so go and check it out.

MIT Licenced

### yutkat
[yutkat](https://github.com/yutkat/dotfiles/)'s install script was a good referance for many things. I copied a few of the helper functions from him. Overall it seems like a good tool, it just does a few things a bit differently than I would like. It also comes with a gui mode which I never got to try out, and which I might at some point.

MIT Licenced

### chezmoi
[chezmoi](https://github.com/twpayne/chezmoi) was an insparation, though I don't use any code from them as it is a go binary. While looking for a solution for managing my dotfiles chezmoi came up time and time again and a potential option. However, when actually using it, it just did not click for me. It seems like a great tool and probably better than `sagedot` but it just wasn't in the cards.

Anyways I borrow several ideas from them because they also deal with flat files. Things like scripts, `run_*.sh`, `run_once_*.sh`, and `run_onchange_*.sh` coming from them.

MIT Licenced