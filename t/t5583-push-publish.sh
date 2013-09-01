#!/bin/sh

test_description='push with --set-publish'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=master

. ./test-lib.sh

test_expect_success 'setup bare parent' '
	git init --bare parent &&
	git remote add publish parent
'

test_expect_success 'setup local commit' '
	echo content >file &&
	git add file &&
	git commit -m one
'

check_config() {
	(echo $2; echo $3) >expect.$1
	(git config branch.$1.pushremote
	 git config branch.$1.push) >actual.$1
	test_cmp expect.$1 actual.$1
}

test_expect_success 'push -p master:master' '
	git push -p publish master:master &&
	check_config master publish refs/heads/master
'

test_expect_success 'push -u master:other' '
	git push -p publish master:other &&
	check_config master publish refs/heads/other
'

test_expect_success 'push -p --dry-run master:otherX' '
	git push -p --dry-run publish master:otherX &&
	check_config master publish refs/heads/other
'

test_expect_success 'push -p master2:master2' '
	git branch master2 &&
	git push -p publish master2:master2 &&
	check_config master2 publish refs/heads/master2
'

test_expect_success 'push -p master2:other2' '
	git push -p publish master2:other2 &&
	check_config master2 publish refs/heads/other2
'

test_expect_success 'push -p :master2' '
	git push -p publish :master2 &&
	check_config master2 publish refs/heads/other2
'

test_expect_success 'push -u --all' '
	git branch all1 &&
	git branch all2 &&
	git push -p --all &&
	check_config all1 publish refs/heads/all1 &&
	check_config all2 publish refs/heads/all2
'

test_expect_success 'push -p HEAD' '
	git checkout -b headbranch &&
	git push -p publish HEAD &&
	check_config headbranch publish refs/heads/headbranch
'

test_done
