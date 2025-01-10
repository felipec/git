_git_fast_forward ()
{
	case "$cur" in
	--*)
		__gitcomp_builtin fast-forward
		return
	esac
	__git_complete_refs
}

_git_stage ()
{
	if [[ "$cur" == --* ]]; then
		__gitcomp_builtin stage
		return
	fi

	_git_add
}

_git_update ()
{
	case "$cur" in
	--*)
		__gitcomp_builtin update

		return
		;;
	esac
	__git_complete_remote_or_refspec
}
