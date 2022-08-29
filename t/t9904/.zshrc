setopt zle
setopt list_rows_first

PS1="<PROMPT>"
fpath=($ZDOTDIR $fpath)
LISTMAX=1000

autoload -U compinit && compinit -u

zstyle ':completion:*:*:git:*' script "$SRC_DIR/git-completion.bash"
zstyle ':completion:*' list-colors "no=<MARK>" "fi=<MARK>" "di=<MARK>" "ec=</MARK>\n" "rc=" "lc=" "sp="
zstyle ':completion:*' verbose no

zle_complete () {
	zle list-choices
	zle kill-whole-line
	print "<END-CHOICES>"
}
zle -N zle_complete
bindkey "^I" zle_complete

functions[_default]=:

compadd () {
	local pfx sfx
	local -a args

	if (( ${@[(I)-a|-d]} )); then
		builtin compadd -V unsorted "$@"
	else
		while (($#)); do
			case "$1" in
			-p) pfx="$2" ; shift 2 ;;
			-S) sfx="$2" ; shift 2 ;;
			--) args+=($1) ; shift ; break ;;
			*) args+=("$1") ; shift ;;
			esac
		done

		while (($#)); do
			args+=(${pfx}$1${sfx})
			shift
		done

		builtin compadd -V unsorted -S '' "${args[@]}"
	fi
}

_git_func () {
	eval ${words[2,-2]}
}
