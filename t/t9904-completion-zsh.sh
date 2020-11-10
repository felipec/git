#!/bin/sh
#
# Copyright (c) 2012-2023 Felipe Contreras
#

test_description='test zsh completion'

if test -n "$ZSH_VERSION"; then
	true
elif command -v zsh > /dev/null 2>&1; then
	exec zsh "$0" "$@"
else
	echo '1..0 #SKIP skipping zsh completion tests: zsh not available'
	exit 0
fi

export ZDOTDIR="${0:h:a}/t9904"

. ./test-lib.sh

emulate zsh

zmodload zsh/zpty

export SRC_DIR="$GIT_BUILD_DIR/contrib/completion/"

run_completion ()
{
	local log

	# bug in zsh: reset the exit trap
	zpty zsh "trap - EXIT; zsh -o NO_GLOBAL_RCS"
	zpty -n -w zsh "$1"$'\t'
	zpty -r zsh log '*<END-CHOICES>'
	zpty -d zsh

	printf '%s\n' ${${${(M)${(Qf)log}:#*'<MARK>'*}#*'<MARK>'}%'</MARK>'*} > out

	[[ -s out ]] || { echo > out ; }
}

# Test high-level completion
# Arguments are:
# 1: typed text so far (cur)
# 2: expected completion
test_completion ()
{
	if test $# -gt 1
	then
		printf '%s\n' "$2" >expected
	else
		sed -e 's/Z$//' |sort >expected
	fi &&
	run_completion "$1" &&
	sort -u out >out_sorted &&
	test_cmp expected out_sorted
}

# Test __gitcomp_opts.
# The first argument is the typed text so far (cur); the rest are
# passed to __gitcomp_opts.  Expected output comes is read from the
# standard input, like test_completion().
test_gitcomp_opts ()
{
	sed -e 's/Z$//' >expected &&
	local cur="$1" &&
	shift &&
	run_completion "git func __gitcomp_opts $(printf "%q " "$@") $cur" &&
	test_cmp expected out
}

# Test __gitcomp_nl
# Arguments are:
# 1: current word (cur)
# -: the rest are passed to __gitcomp_nl
test_gitcomp_nl ()
{
	sed -e 's/Z$//' >expected &&
	local cur="$1" &&
	shift &&
	run_completion "git func __gitcomp_nl $(printf "%q " "$@") $cur" &&
	test_cmp expected out
}

actual="$TRASH_DIRECTORY/actual"

if test_have_prereq MINGW
then
	ROOT="$(pwd -W)"
else
	ROOT="$(pwd)"
fi

test_expect_success 'setup for __git_find_repo_path/__gitdir tests' '
	mkdir -p subdir/subsubdir &&
	mkdir -p non-repo &&
	git init -b main otherrepo
'

test_expect_success '__gitcomp_opts - trailing space - options' '
	test_gitcomp_opts "--re" "--dry-run --reuse-message= --reedit-message=
		--reset-author" <<-EOF
	--reuse-message=Z
	--reedit-message=Z
	--reset-author Z
	EOF
'

test_expect_success '__gitcomp_opts - trailing space - config keys' '
	test_gitcomp_opts "br" "branch. branch.autosetupmerge
		branch.autosetuprebase browser." <<-\EOF
	branch.Z
	branch.autosetupmerge Z
	branch.autosetuprebase Z
	browser.Z
	EOF
'

test_expect_success '__gitcomp_opts - option parameter' '
	test_gitcomp_opts "--strategy=re" "octopus ours recursive resolve subtree" \
		"" "re" <<-\EOF
	recursive Z
	resolve Z
	EOF
'

test_expect_failure '__gitcomp_opts - prefix' '
	test_gitcomp_opts "branch.maint.me" "remote merge mergeoptions rebase" \
		"branch.maint." "me" <<-\EOF
	branch.maint.merge Z
	branch.maint.mergeoptions Z
	EOF
'

test_expect_failure '__gitcomp_opts - suffix' '
	test_gitcomp_opts "branch.ma" "master maint next seen" "branch." \
		"ma" "." <<-\EOF
	branch.master.Z
	branch.maint.Z
	EOF
'

test_expect_success '__gitcomp_opts - ignore optional negative options' '
	test_gitcomp_opts "--" "--abc --def --no-one -- --no-two" <<-\EOF
	--abc Z
	--def Z
	--no-one Z
	--no-... Z
	EOF
'

test_expect_success '__gitcomp_opts - ignore/narrow optional negative options' '
	test_gitcomp_opts "--a" "--abc --abcdef --no-one -- --no-two" <<-\EOF
	--abc Z
	--abcdef Z
	EOF
'

test_expect_success '__gitcomp_opts - ignore/narrow optional negative options' '
	test_gitcomp_opts "--n" "--abc --def --no-one -- --no-two" <<-\EOF
	--no-one Z
	--no-... Z
	EOF
'

test_expect_success '__gitcomp_opts - expand all negative options' '
	test_gitcomp_opts "--no-" "--abc --def --no-one -- --no-two" <<-\EOF
	--no-one Z
	--no-two Z
	EOF
'

test_expect_success '__gitcomp_opts - expand/narrow all negative options' '
	test_gitcomp_opts "--no-o" "--abc --def --no-one -- --no-two" <<-\EOF
	--no-one Z
	EOF
'

test_expect_success '__gitcomp_opts - equal skip' '
	test_gitcomp_opts "--option=" "--option=" <<-\EOF &&

	EOF
	test_gitcomp_opts "option=" "option=" <<-\EOF

	EOF
'

read -r -d "" refs <<-\EOF
main
maint
next
seen
EOF

test_expect_success '__gitcomp_nl - trailing space' '
	test_gitcomp_nl "m" "$refs" <<-EOF
	main Z
	maint Z
	EOF
'

test_expect_success '__gitcomp_nl - prefix' '
	test_gitcomp_nl "branch.m" "$refs" "branch." "m" <<-EOF
	branch.main Z
	branch.maint Z
	EOF
'

test_expect_success '__gitcomp_nl - suffix' '
	test_gitcomp_nl "branch.ma" "$refs" "branch." "ma" "." <<-\EOF
	branch.main.Z
	branch.maint.Z
	EOF
'

test_expect_success '__gitcomp_nl - no suffix' '
	test_gitcomp_nl "ma" "$refs" "" "ma" "" <<-\EOF
	mainZ
	maintZ
	EOF
'

test_expect_success 'setup for ref completion' '
	git commit --allow-empty -m initial &&
	git branch -M main &&
	git branch matching-branch &&
	git tag matching-tag &&
	(
		cd otherrepo &&
		git commit --allow-empty -m initial &&
		git branch -m main main-in-other &&
		git branch branch-in-other &&
		git tag tag-in-other
	) &&
	git remote add other "$ROOT/otherrepo/.git" &&
	git fetch --no-tags other &&
	rm -f .git/FETCH_HEAD &&
	git init thirdrepo
'

test_expect_success 'git switch - with no options, complete local branches and unique remote branch names for DWIM logic' '
	test_completion "git switch " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - completes refs and unique remote branches for DWIM' '
	test_completion "git checkout " <<-\EOF
	HEAD Z
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with --no-guess, complete only local branches' '
	test_completion "git switch --no-guess " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - with GIT_COMPLETION_CHECKOUT_NO_GUESS=1, complete only local branches' '
	GIT_COMPLETION_CHECKOUT_NO_GUESS=1 test_completion "git switch " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - --guess overrides GIT_COMPLETION_CHECKOUT_NO_GUESS=1, complete local branches and unique remote names for DWIM logic' '
	GIT_COMPLETION_CHECKOUT_NO_GUESS=1 test_completion "git switch --guess " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - a later --guess overrides previous --no-guess, complete local and remote unique branches for DWIM' '
	test_completion "git switch --no-guess --guess " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - a later --no-guess overrides previous --guess, complete only local branches' '
	test_completion "git switch --guess --no-guess " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - with GIT_COMPLETION_NO_GUESS=1 only completes refs' '
	GIT_COMPLETION_CHECKOUT_NO_GUESS=1 test_completion "git checkout " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - --guess overrides GIT_COMPLETION_NO_GUESS=1, complete refs and unique remote branches for DWIM' '
	GIT_COMPLETION_CHECKOUT_NO_GUESS=1 test_completion "git checkout --guess " <<-\EOF
	HEAD Z
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with --no-guess, only completes refs' '
	test_completion "git checkout --no-guess " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - a later --guess overrides previous --no-guess, complete refs and unique remote branches for DWIM' '
	test_completion "git checkout --no-guess --guess " <<-\EOF
	HEAD Z
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - a later --no-guess overrides previous --guess, complete only refs' '
	test_completion "git checkout --guess --no-guess " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with checkout.guess = false, only completes refs' '
	test_config checkout.guess false &&
	test_completion "git checkout " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with checkout.guess = true, completes refs and unique remote branches for DWIM' '
	test_config checkout.guess true &&
	test_completion "git checkout " <<-\EOF
	HEAD Z
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - a later --guess overrides previous checkout.guess = false, complete refs and unique remote branches for DWIM' '
	test_config checkout.guess false &&
	test_completion "git checkout --guess " <<-\EOF
	HEAD Z
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - a later --no-guess overrides previous checkout.guess = true, complete only refs' '
	test_config checkout.guess true &&
	test_completion "git checkout --no-guess " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with --detach, complete all references' '
	test_completion "git switch --detach " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with --detach, complete only references' '
	test_completion "git checkout --detach " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -d, complete all references' '
	test_completion "git switch -d " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -d, complete only references' '
	test_completion "git checkout -d " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with --track, complete only remote branches' '
	test_completion "git switch --track " <<-\EOF
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with --track, complete only remote branches' '
	test_completion "git checkout --track " <<-\EOF
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with --no-track, complete only local branch names' '
	test_completion "git switch --no-track " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - with --no-track, complete only local references' '
	test_completion "git checkout --no-track " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -c, complete all references' '
	test_completion "git switch -c new-branch " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -C, complete all references' '
	test_completion "git switch -C new-branch " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -c and --track, complete all references' '
	test_completion "git switch -c new-branch --track " <<-EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -C and --track, complete all references' '
	test_completion "git switch -C new-branch --track " <<-EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -c and --no-track, complete all references' '
	test_completion "git switch -c new-branch --no-track " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - with -C and --no-track, complete all references' '
	test_completion "git switch -C new-branch --no-track " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b, complete all references' '
	test_completion "git checkout -b new-branch " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B, complete all references' '
	test_completion "git checkout -B new-branch " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b and --track, complete all references' '
	test_completion "git checkout -b new-branch --track " <<-EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B and --track, complete all references' '
	test_completion "git checkout -B new-branch --track " <<-EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b and --no-track, complete all references' '
	test_completion "git checkout -b new-branch --no-track " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B and --no-track, complete all references' '
	test_completion "git checkout -B new-branch --no-track " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'git switch - for -c, complete local branches and unique remote branches' '
	test_completion "git switch -c " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -C, complete local branches and unique remote branches' '
	test_completion "git switch -C " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -c with --no-guess, complete local branches only' '
	test_completion "git switch --no-guess -c " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -C with --no-guess, complete local branches only' '
	test_completion "git switch --no-guess -C " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -c with --no-track, complete local branches only' '
	test_completion "git switch --no-track -c " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -C with --no-track, complete local branches only' '
	test_completion "git switch --no-track -C " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -b, complete local branches and unique remote branches' '
	test_completion "git checkout -b " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -B, complete local branches and unique remote branches' '
	test_completion "git checkout -B " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -b with --no-guess, complete local branches only' '
	test_completion "git checkout --no-guess -b " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -B with --no-guess, complete local branches only' '
	test_completion "git checkout --no-guess -B " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -b with --no-track, complete local branches only' '
	test_completion "git checkout --no-track -b " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -B with --no-track, complete local branches only' '
	test_completion "git checkout --no-track -B " <<-\EOF
	main Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - with --orphan completes local branch names and unique remote branch names' '
	test_completion "git switch --orphan " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - --orphan with branch already provided completes nothing else' '
	test_completion "git switch --orphan main " <<-\EOF

	EOF
'

test_expect_success 'git checkout - with --orphan completes local branch names and unique remote branch names' '
	test_completion "git checkout --orphan " <<-\EOF
	branch-in-other Z
	main Z
	main-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - --orphan with branch already provided completes local refs for a start-point' '
	test_completion "git checkout --orphan main " <<-\EOF
	HEAD Z
	main Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/main-in-other Z
	EOF
'

test_expect_success 'teardown after ref completion' '
	git branch -d matching-branch &&
	git tag -d matching-tag &&
	git remote remove other
'

test_expect_success 'basic' '
	run_completion "git " &&
	# built-in
	grep -q "^add\$" out &&
	# script
	grep -q "^rebase\$" out &&
	# plumbing
	! grep -q "^ls-files\$" out &&

	run_completion "git r" &&
	! grep -q -v "^r" out
'

test_expect_success 'double dash "git" itself' '
	test_completion "git --" <<-\EOF
	--paginate
	--no-pager
	--git-dir
	--bare
	--version
	--exec-path
	--html-path
	--man-path
	--info-path
	--work-tree
	--namespace
	--no-replace-objects
	--help
	EOF
'

test_expect_success 'double dash "git checkout"' '
	test_completion "git checkout --" <<-\EOF
	--quiet Z
	--detach Z
	--track Z
	--orphan=Z
	--ours Z
	--theirs Z
	--merge Z
	--conflict=Z
	--patch Z
	--ignore-skip-worktree-bits Z
	--ignore-other-worktrees Z
	--recurse-submodules Z
	--progress Z
	--guess Z
	--no-guess Z
	--no-... Z
	--overlay Z
	--pathspec-file-nul Z
	--pathspec-from-file=Z
	EOF
'

test_expect_success 'general options' '
	test_completion "git --ver" "--version" &&
	test_completion "git --hel" "--help" &&
	test_completion "git --exe" "--exec-path" &&
	test_completion "git --htm" "--html-path" &&
	test_completion "git --pag" "--paginate" &&
	test_completion "git --no-p" "--no-pager" &&
	test_completion "git --git" "--git-dir" &&
	test_completion "git --wor" "--work-tree" &&
	test_completion "git --nam" "--namespace" &&
	test_completion "git --bar" "--bare" &&
	test_completion "git --inf" "--info-path" &&
	test_completion "git --no-r" "--no-replace-objects"
'

test_expect_success 'general options plus command' '
	test_completion "git --version check" "" &&
	test_completion "git --paginate check" "checkout" &&
	test_completion "git --git-dir=foo check" "checkout" &&
	test_completion "git --bare check" "checkout" &&
	test_completion "git --exec-path=foo check" "checkout" &&
	test_completion "git --html-path check" "" &&
	test_completion "git --no-pager check" "checkout" &&
	test_completion "git --work-tree=foo check" "checkout" &&
	test_completion "git --namespace=foo check" "checkout" &&
	test_completion "git --paginate check" "checkout" &&
	test_completion "git --info-path check" "" &&
	test_completion "git --no-replace-objects check" "checkout" &&
	test_completion "git --git-dir some/path check" "checkout" &&
	test_completion "git -c conf.var=value check" "checkout" &&
	test_completion "git -C some/path check" "checkout" &&
	test_completion "git --work-tree some/path check" "checkout" &&
	test_completion "git --namespace name/space check" "checkout"
'

test_expect_success 'git --help completion' '
	test_completion "git --help ad" "add " &&
	test_completion "git --help core" "core-tutorial "
'

test_expect_success 'setup for integration tests' '
	echo content >file1 &&
	echo more >file2 &&
	git add file1 file2 &&
	git commit -m one &&
	git branch mybranch &&
	git tag mytag
'

test_expect_success 'checkout completes ref names' '
	test_completion "git checkout m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success 'git -C <path> checkout uses the right repo' '
	test_completion "git -C subdir -C subsubdir -C .. -C ../otherrepo checkout b" <<-\EOF
	branch-in-other Z
	EOF
'

test_expect_success 'show completes all refs' '
	test_completion "git show m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success '<ref>: completes paths' '
	test_completion "git show mytag:f" <<-\EOF
	file1Z
	file2Z
	EOF
'

test_expect_success 'complete tree filename with spaces' '
	echo content >"name with spaces" &&
	git add "name with spaces" &&
	git commit -m spaces &&
	test_completion "git show HEAD:nam" <<-\EOF
	name with spacesZ
	EOF
'

test_expect_success 'complete tree filename with metacharacters' '
	echo content >"name with \${meta}" &&
	git add "name with \${meta}" &&
	git commit -m meta &&
	test_completion "git show HEAD:nam" <<-\EOF
	name with ${meta}Z
	name with spacesZ
	EOF
'

test_expect_success PERL 'send-email' '
	test_completion "git send-email --cov" <<-\EOF &&
	--cover-from-description=Z
	--cover-letter Z
	EOF
	test_completion "git send-email --val" <<-\EOF &&
	--validate Z
	EOF
	test_completion "git send-email ma" "main "
'

test_expect_success 'complete files' '
	git init tmp && cd tmp &&
	test_when_finished "cd .. && rm -rf tmp" &&

	echo "expected" > .gitignore &&
	echo "out" >> .gitignore &&
	echo "out_sorted" >> .gitignore &&

	git add .gitignore &&
	test_completion "git commit " ".gitignore" &&

	git commit -m ignore &&

	touch new &&
	test_completion "git add " "new" &&

	git add new &&
	git commit -a -m new &&
	test_completion "git add " "" &&

	git mv new modified &&
	echo modify > modified &&
	test_completion "git add " "modified" &&

	mkdir -p some/deep &&
	touch some/deep/path &&
	test_completion "git add some/" "some/deep" &&
	git clean -f some &&

	touch untracked &&

	: TODO .gitignore should not be here &&
	test_completion "git rm " <<-\EOF &&
	.gitignore
	modified
	EOF

	test_completion "git clean " "untracked" &&

	: TODO .gitignore should not be here &&
	test_completion "git mv " <<-\EOF &&
	.gitignore
	modified
	EOF

	mkdir dir &&
	touch dir/file-in-dir &&
	git add dir/file-in-dir &&
	git commit -m dir &&

	mkdir untracked-dir &&

	: TODO .gitignore should not be here &&
	test_completion "git mv modified " <<-\EOF &&
	.gitignore
	dir
	modified
	untracked
	untracked-dir
	EOF

	test_completion "git commit " "modified" &&

	: TODO .gitignore should not be here &&
	test_completion "git ls-files " <<-\EOF &&
	.gitignore
	dir
	modified
	EOF

	touch momified &&
	test_completion "git add mom" "momified"
'

test_expect_success "simple alias" '
	test_config alias.co checkout &&
	test_completion "git co m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success "recursive alias" '
	test_config alias.co checkout &&
	test_config alias.cod "co --detached" &&
	test_completion "git cod m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success "completion uses <cmd> completion for alias: !sh -c 'git <cmd> ...'" '
	test_config_global alias.co "!sh -c '"'"'git checkout ...'"'"'" &&
	test_completion "git co m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success 'completion uses <cmd> completion for alias: !f () { VAR=val git <cmd> ... }' '
	test_config_global alias.co "!f () { VAR=val git checkout ... ; } f" &&
	test_completion "git co m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success 'completion used <cmd> completion for alias: !f() { : git <cmd> ; ... }' '
	test_config_global alias.co "!f() { : git checkout ; if ... } f" &&
	test_completion "git co m" <<-\EOF
	main Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success 'completion without explicit _git_xxx function' '
	test_completion "git version --" <<-\EOF
	--build-options Z
	--no-build-options Z
	EOF
'

test_expect_failure 'complete with tilde expansion' '
	git init tmp && cd tmp &&
	test_when_finished "cd .. && rm -rf tmp" &&

	touch ~/tmp/file &&

	test_completion "git add ~/tmp/" "~/tmp/file"
'

test_expect_success 'setup other remote for remote reference completion' '
	git remote add other otherrepo &&
	git fetch other
'

test_expect_success 'git config - section' '
	test_completion "git config br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_success 'git config - section include, includeIf' '
	test_completion "git config inclu" <<-\EOF
	include.Z
	includeIf.Z
	EOF
'

test_expect_success 'git config - variable name' '
	test_completion "git config log.d" <<-\EOF
	log.date Z
	log.decorate Z
	log.diffMerges Z
	EOF
'

test_expect_success 'git config - variable name include' '
	test_completion "git config include.p" <<-\EOF
	include.path Z
	EOF
'

test_expect_success 'git config - value' '
	test_completion "git config color.pager " <<-\EOF
	false Z
	true Z
	EOF
'

test_expect_success 'git config - direct completions' '
	test_completion "git config branch.autoSetup" <<-\EOF
	branch.autoSetupMerge Z
	branch.autoSetupRebase Z
	EOF
'

test_expect_success 'git -c - section' '
	test_completion "git -c br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_success 'git -c - variable name' '
	test_completion "git -c log.d" <<-\EOF
	log.date=Z
	log.decorate=Z
	log.diffMerges=Z
	EOF
'

test_expect_success 'git -c - value' '
	test_completion "git -c color.pager=" <<-\EOF
	false Z
	true Z
	EOF
'

test_expect_success 'git clone --config= - section' '
	test_completion "git clone --config=br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_success 'git clone --config= - variable name' '
	test_completion "git clone --config=log.d" <<-\EOF
	log.date=Z
	log.decorate=Z
	log.diffMerges=Z
	EOF
'

test_expect_success 'git clone --config= - value' '
	test_completion "git clone --config=color.pager=" <<-\EOF
	false Z
	true Z
	EOF
'

test_expect_success 'options with value' '
	test_completion "git merge -X diff-algorithm=" <<-\EOF

	EOF
'

test_expect_success 'main sets correct __git_cmd_idx' '
	echo modified > file1 &&
	touch file3 &&
	test_completion "compdef _git ga=git_add${LF}ga --update f" "file1"
'

test_done
