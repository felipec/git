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

test_done
