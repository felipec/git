#!/bin/sh

test_description='update'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=master
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

check_msg () {
	test "$2" != "master" && into=" into '$2'"
	echo "Merge branch '$1'${into}" > expected
	git log -1 --format=%s > actual &&
	test_cmp expected actual
}

test_expect_success 'setup' '
	echo one > file &&
	git add file &&
	git commit -a -m one &&
	echo two > file &&
	git commit -a -m two
'

test_expect_success 'basic update' '
	test_when_finished "rm -rf test" &&
	(
	git clone . test &&
	cd test &&
	git reset --hard @^ &&
	git update &&
	test_cmp_rev master origin/master
	)
'

test_expect_success 'non-fast-forward update' '
	test_when_finished "rm -rf test" &&
	(
	git clone . test &&
	cd test &&
	git checkout -b other master^ &&
	>new &&
	git add new &&
	git commit -m new &&
	git checkout -b test -t other &&
	git reset --hard master &&
	test_must_fail git update &&
	test_cmp_rev @ master
	)
'

test_expect_success 'git update non-fast-forward with merge' '
	test_when_finished "rm -rf test" &&
	(
	git clone . test &&
	cd test &&
	git checkout -b other master^ &&
	>new &&
	git add new &&
	git commit -m new &&
	git checkout -b test -t other &&
	git reset --hard master &&
	git update --merge &&
	test_cmp_rev @^2 master &&
	test_cmp_rev @^1 other &&
	check_msg test other
	)
'

test_expect_success 'git update non-fast-forward with rebase' '
	test_when_finished "rm -rf test" &&
	(
	git clone . test &&
	cd test &&
	git checkout -b other master^ &&
	>new &&
	git add new &&
	git commit -m new &&
	git checkout -b test -t other &&
	git reset --hard master &&
	git update --rebase &&
	test_cmp_rev @^ other &&
	test_must_fail git rev-parse --verify -q @^2
	)
'

test_done
