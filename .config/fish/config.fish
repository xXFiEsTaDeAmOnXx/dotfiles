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

# Changing "ls" to "exa"
alias ls='eza -al  --color=always --group-directories-first' # my preferred listing
alias la='eza -a --color=always --group-directories-first'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first'  # long format
alias lt='eza -aT --color=always --group-directories-first' # tree listing
alias l.='eza -a | egrep "^\."'

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
alias grep='grep --color=auto'

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

starship init fish | source
if test -f  ~/.cache/ags/user/generated/terminal/sequences.txt
    cat  ~/.cache/ags/user/generated/terminal/sequences.txt
end


# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
