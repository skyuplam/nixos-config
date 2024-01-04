# ------------------
# Add Completion sources
# ------------------
[ -d $HOME/.zfunc ] && fpath=($HOME/.zfunc $fpath)
[ -d $HOME/dev/nix-zsh-completions ] && fpath=($HOME/dev/nix-zsh-completions $fpath)
[ -d /etc/profiles/per-user/terrencelam/share/zsh/site-functions ] && fpath=(/etc/profiles/per-user/terrencelam/share/zsh/site-functions $fpath)
[ -d /usr/local/share/zsh/site-functions ] && fpath=(/usr/local/share/zsh/site-functions $fpath)
[ -d /opt/homebrew/share/zsh/site-functions ] && fpath=(/opt/homebrew/share/zsh/site-functions(N) ${fpath})

