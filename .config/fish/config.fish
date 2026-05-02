function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

### ALIASES ###

# we onyl use vancy colors and prompt outside of tty
set VANCY_PROMPT no
if [ "$TERM" != "linux" ] 
  set VANCY_PROMPT yes
end

# Changing "ls" to "exa"
if test "$VANCY_PROMPT" = "yes"
  alias ls='eza -al  --color=always --group-directories-first' # my preferred listing
  alias la='eza -a --color=always --group-directories-first'  # all files and dirs
  alias ll='eza -l --color=always --group-directories-first'  # long format
  alias lt='eza -aT --color=always --group-directories-first' # tree listing
  alias l.='eza -a | egrep "^\."'
else
  alias ls='eza -al  --color=never --group-directories-first' # my preferred listing
  alias la='eza -a --color=never --group-directories-first'  # all files and dirs
  alias ll='eza -l --color=never --group-directories-first'  # long format
  alias lt='eza -aT --color=never --group-directories-first' # tree listing
  alias l.='eza -a | egrep "^\."'
end

# pacman and yay
alias pacsyu='sudo pacman -Syu'                  # update only standard pkgs
alias pacsyyu='sudo pacman -Syyu'                # Refresh pkglist & update standard pkgs
alias yaysua='yay -Sua --noconfirm'              # update only AUR pkgs (yay)
alias yaysyu='yay -Syu --noconfirm'              # update standard pkgs and AUR pkgs (yay)
alias unlock='sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)' # remove orphaned packages


# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'

# use neovim isntead of vim
alias vim='nvim '



# Colorize grep output (good for log files)
if test $VANCY_PROMPT = yes
    alias grep 'grep --color=auto'
end

# git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias stat='git status'  # 'status' is protected name so using 'stat' instead
alias tag='git tag'
alias newtag='git tag -a'


# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

#search for a file
alias search="fzf --preview 'bat --color=always {}'"


# use zoxide
alias z="zoxide"
zoxide init fish | source

if test "$VANCY_PROMPT" = "yes"
starship init fish | source
   if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
      cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
  end
end


# for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end


set -x TERM xterm-256color # fix for ssh

set -x ROS_DOMAIN_ID 97
set -x TIAGO_BASE pal@192.168.66.66
set -x TIAGO_ZOTAK_BOX iki@192.168.66.67
set -x TIAGO_JETSON iki@192.168.66.68
set -x TIAGO_STEAMDECK  iki@192.168.66.69
set -x KATE_ZOTAK_BOX iki@192.168.77.77



function robocup_ws
    docker compose -f $HOME/dotfiles/scripts/robocup_workspace.yml run --rm -it $argv -- bash
end

function opencode_ws
    docker compose -f $HOME/dotfiles/scripts/opencode_workspace.yml run --rm -it opencode  opencode
end

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
