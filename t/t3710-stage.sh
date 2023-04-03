#!/bin/sh
#
# Copyright (C) 2021 Felipe Contreras
#

test_description='Tests of git stage'

. ./test-lib.sh

in_stage () {
	test "$(git ls-files "$1")" = "$1"
}

test_expect_success 'basic' '
	touch foo &&
	git stage foo &&
	in_stage foo
'

test_expect_success 'add' '
	touch bar &&
	git stage --add bar &&
	in_stage bar
'

test_expect_success 'remove' '
	git stage --remove bar &&
	! in_stage bar
'

test_expect_success 'unstage' '
	touch bar &&
	git stage bar &&
	git unstage bar &&
	! in_stage bar
'

test_expect_success 'diff' '
	echo foo > foo &&
	git stage --add foo &&
	git stage --diff > out &&
	test_file_not_empty out
'

test_expect_success 'edit' '
	GIT_EDITOR="sed -i -e \"s/^+foo$/+edit/\"" git stage --edit &&
	git stage --diff > out &&
	grep "^+edit$" out
'

test_expect_success 'prefix' '
	touch topfile &&
	mkdir subdir &&
	cd subdir &&
	git stage --add ../topfile &&
	in_stage ../topfile
'

test_done
