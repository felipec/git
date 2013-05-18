#!/bin/sh

test_description='fetch follows remote-tracking branches correctly'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=master
TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success setup '
	>file &&
	git add . &&
	test_tick &&
	git commit -m Initial &&
	git branch b-0 &&
	git branch b1 &&
	git branch b/one &&
	test_create_repo other &&
	(
		cd other &&
		git config remote.origin.url .. &&
		git config remote.origin.fetch "+refs/heads/b/*:refs/remotes/b/*"
	)
'

test_expect_success fetch '
	(
		cd other && git fetch origin &&
		test "$(git for-each-ref --format="%(refname)")" = refs/remotes/b/one
	)
'

cat > expected_current <<EOF
	branch 'master' of .
EOF

cat > expected_sane <<EOF
not-for-merge	branch 'b-0' of ..
not-for-merge	branch 'b/one' of ..
not-for-merge	branch 'b1' of ..
not-for-merge	branch 'master' of ..
EOF

test_fetch_default() {
	test_when_finished "rm -rf another" &&

	(
		test_create_repo another &&
		cd another &&
		git remote add origin .. &&
		test_commit test &&
		git checkout -t -b local-tracking master &&
		git fetch &&
		cut -f2- .git/FETCH_HEAD > actual &&
		test_cmp "../expected_$1" actual
	)
}

test_expect_success 'fetch default' '
	test_fetch_default current
'

test_expect_success 'fetch default current' '
	test_config_global fetch.default current &&
	test_fetch_default current
'

test_expect_success 'fetch default sane' '
	test_config_global fetch.default sane &&
	test_fetch_default sane
'

test_done
