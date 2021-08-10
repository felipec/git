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

test_done
