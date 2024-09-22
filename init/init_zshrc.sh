#! /bin/bash

cat >> ~/.zshrc << 'EOFF'
alias psqll='sudo -i -u postgres psql'
# cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
# lsd
alias ls='lsd'
alias lsl='lsd -lF'
alias lsal='lsd -alF'
alias la='lsd -a'
alias ll='lsd -lh'
alias lr='lsd -lR'

# ps
alias psmem='ps aux --sort=%mem'
alias pscpu='ps aux --sort=%cpu'

# procs
alias pcs='procs'
alias pcsmem='procs --sortd mem'
alias pcscpu='procs --sortd cpu'

# ufw
alias ufws='ufw status numbered'

# systemctl
alias sc='systemctl'
alias sce='systemctl enable --now'
alias scr='systemctl restart'
alias scs='systemctl status'
alias sclist='systemctl list-units --type=service'

# abbr
alias dc='docker-compose'
alias myip='curl -s http://checkip.amazonaws.com/'
alias myip6='curl ip.sb -6'
alias tma='tmux attach -t'
alias tmn='tmux new -s'
alias tmk='tmux kill-session -t'
alias x='extract'
alias z='__zoxide_z'
alias sst='ss -tnlp'
alias ssu='ss -unlp'
alias sstg='ss -tnlp | grep'

# zoxide
eval "$(zoxide init --no-cmd zsh)"
# starship
eval "$(starship init zsh)"
# self-defined functions
fpath=( ~/.zfunc "${fpath[@]}" )
autoload -Uz extract
EOFF

# extract function
cat >> /root/.zfunc/extract << 'EOFF'
extract() {
  setopt localoptions noautopushd
  if (( $# == 0 )); then
    cat >&2 <<'EOF'
Usage: extract [-option] [file ...]
Options:
    -r, --remove    Remove archive after unpacking.
EOF
  fi
  local remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi
  local pwd="$PWD"
  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" >&2
      shift
      continue
    fi
    local success=0
    local extract_dir="${1:t:r}"
    local file="$1" full_path="${1:A}"
    case "${file:l}" in
      (*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$file" | tar xv } || tar zxvf "$file" ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$file" ;;
      (*.tar.xz|*.txz)
        tar --xz --help &> /dev/null \
        && tar --xz -xvf "$file" \
        || xzcat "$file" | tar xvf - ;;
      (*.tar.zma|*.tlz)
        tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$file" \
        || lzcat "$file" | tar xvf - ;;
      (*.tar.zst|*.tzst)
        tar --zstd --help &> /dev/null \
        && tar --zstd -xvf "$file" \
        || zstdcat "$file" | tar xvf - ;;
      (*.tar) tar xvf "$file" ;;
      (*.tar.lz) (( $+commands[lzip] )) && tar xvf "$file" ;;
      (*.tar.lz4) lz4 -c -d "$file" | tar xvf - ;;
      (*.tar.lrz) (( $+commands[lrzuntar] )) && lrzuntar "$file" ;;
      (*.gz) (( $+commands[pigz] )) && pigz -dk "$file" || gunzip -k "$file" ;;
      (*.bz2) bunzip2 "$file" ;;
      (*.xz) unxz "$file" ;;
      (*.lrz) (( $+commands[lrunzip] )) && lrunzip "$file" ;;
      (*.lz4) lz4 -d "$file" ;;
      (*.lzma) unlzma "$file" ;;
      (*.z) uncompress "$file" ;;
      (*.zip|*.war|*.jar|*.ear|*.sublime-package|*.ipa|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$file" -d "$extract_dir" ;;
      (*.rar) unrar x -ad "$file" ;;
      (*.rpm)
        command mkdir -p "$extract_dir" && builtin cd -q "$extract_dir" \
        && rpm2cpio "$full_path" | cpio --quiet -id ;;
      (*.7z) 7za x "$file" ;;
      (*.deb)
        command mkdir -p "$extract_dir/control" "$extract_dir/data"
        builtin cd -q "$extract_dir"; ar vx "$full_path" > /dev/null
        builtin cd -q control; extract ../control.tar.*
        builtin cd -q ../data; extract ../data.tar.*
        builtin cd -q ..; command rm *.tar.* debian-binary ;;
      (*.zst) unzstd "$file" ;;
      (*.cab) cabextract -d "$extract_dir" "$file" ;;
      (*.cpio) cpio -idmvF "$file" ;;
      (*)
        echo "extract: '$file' cannot be extracted" >&2
        success=1 ;;
    esac
    (( success = success > 0 ? success : $? ))
    (( success == 0 && remove_archive == 0 )) && rm "$full_path"
    shift
    # Go back to original working directory in case we ran cd previously
    builtin cd -q "$pwd"
  done
}
EOFF