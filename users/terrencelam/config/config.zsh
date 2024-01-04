# ---------------------------------------------------------
# GPG {{{
# ---------------------------------------------------------
if type gpg-connect-agent > /dev/null; then
  gpg-connect-agent updatestartuptty /bye >/dev/null
fi
# }}}
# ---------------------------------------------------------
# OSC integration {{{
# ---------------------------------------------------------
function osc7-pwd() {
    emulate -L zsh # also sets localoptions for us
    setopt extendedglob
    local LC_ALL=C
    printf '\e]7;file://%s%s\e\' $HOST ${PWD//(#m)([^@-Za-z&-;_~])/%${(l:2::0:)$(([##16]#MATCH))}}
}

function chpwd-osc7-pwd() {
    (( ZSH_SUBSHELL )) || osc7-pwd
}

add-zsh-hook -Uz chpwd chpwd-osc7-pwd

# Jumping between prompts
precmd() {
    print -Pn "\e]133;A\e\\"
}

# }}}
# ---------------------------------------------------------
# Sourcing other configs {{{
# ---------------------------------------------------------

[ -f ~/.zsh/local.zsh ] && source ~/.zsh/local.zsh

# }}}
