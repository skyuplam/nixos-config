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

# Map inputs
if [ $TERM = "xterm-256color" ]; then  
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    # other ZSH_AUTOSUGGEST config goes here

    # Then load url-quote-magic and bracketed-paste-magic as above
    autoload -U url-quote-magic bracketed-paste-magic
    zle -N self-insert url-quote-magic
    zle -N bracketed-paste bracketed-paste-magic

    # Now the fix, setup these two hooks:
    pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic 
    }
    pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
    }
    zstyle :bracketed-paste-magic paste-init pasteinit
    zstyle :bracketed-paste-magic paste-finish pastefinish

    # and finally, make sure zsh-autosuggestions does not interfere with it:
    ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)
fi


[[ ${TERM} != dumb ]] && () {

  # Use human-friendly identifiers.
  zmodload -F zsh/terminfo +b:echoti +p:terminfo
  typeset -gA key_info
  key_info=(
    Control      '\C-'
    ControlLeft  '\e[1;5D \e[5D \e\e[D \eOd \eOD'
    ControlRight '\e[1;5C \e[5C \e\e[C \eOc \eOC'
    Escape       '\e'
    Meta         '\M-'
    Backspace    '^?'
    Delete       '^[[3~'
    BackTab      "${terminfo[kcbt]}"
    Left         "${terminfo[kcub1]}"
    Down         "${terminfo[kcud1]}"
    Right        "${terminfo[kcuf1]}"
    Up           "${terminfo[kcuu1]}"
    End          "${terminfo[kend]}"
    F1           "${terminfo[kf1]}"
    F2           "${terminfo[kf2]}"
    F3           "${terminfo[kf3]}"
    F4           "${terminfo[kf4]}"
    F5           "${terminfo[kf5]}"
    F6           "${terminfo[kf6]}"
    F7           "${terminfo[kf7]}"
    F8           "${terminfo[kf8]}"
    F9           "${terminfo[kf9]}"
    F10          "${terminfo[kf10]}"
    F11          "${terminfo[kf11]}"
    F12          "${terminfo[kf12]}"
    Home         "${terminfo[khome]}"
    Insert       "${terminfo[kich1]}"
    PageDown     "${terminfo[knp]}"
    PageUp       "${terminfo[kpp]}"
  )

  # Bind the keys

  local key
  for key (${(s: :)key_info[ControlLeft]}) bindkey ${key} backward-word
  for key (${(s: :)key_info[ControlRight]}) bindkey ${key} forward-word

  bindkey ${key_info[Backspace]} backward-delete-char
  bindkey ${key_info[Delete]} delete-char

  if [[ -n ${key_info[Home]} ]] bindkey ${key_info[Home]} beginning-of-line
  if [[ -n ${key_info[End]} ]] bindkey ${key_info[End]} end-of-line

  if [[ -n ${key_info[PageUp]} ]] bindkey ${key_info[PageUp]} up-line-or-history
  if [[ -n ${key_info[PageDown]} ]] bindkey ${key_info[PageDown]} down-line-or-history

  if [[ -n ${key_info[Insert]} ]] bindkey ${key_info[Insert]} overwrite-mode

  if [[ -n ${key_info[Left]} ]] bindkey ${key_info[Left]} backward-char
  if [[ -n ${key_info[Right]} ]] bindkey ${key_info[Right]} forward-char

  # Expandpace.
  bindkey ' ' magic-space

  # Bind insert-last-word even in viins mode
  bindkey "${key_info[Escape]}." insert-last-word
  bindkey "${key_info[Escape]}_" insert-last-word

  # <Ctrl-x><Ctrl-e> to edit command-line in EDITOR
  autoload -Uz edit-command-line && zle -N edit-command-line && \
      bindkey "${key_info[Control]}x${key_info[Control]}e" edit-command-line

  # Bind <Shift-Tab> to go to the previous menu item.
  if [[ -n ${key_info[BackTab]} ]] bindkey ${key_info[BackTab]} reverse-menu-complete
}

# Wordchars
export WORDCHARS=''

# }}}
# ---------------------------------------------------------
# Sourcing other configs {{{
# ---------------------------------------------------------

[ -f ~/.zsh/local.zsh ] && source ~/.zsh/local.zsh

# }}}
