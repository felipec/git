/*
 * Copyright (C) 2021 Felipe Contreras
 */

#include "builtin.h"
#include "run-command.h"
#include "dir.h"

static int run_fetch(void)
{
	struct strvec args = STRVEC_INIT;
	int ret;

	strvec_pushl(&args, "fetch", "--update-head-ok", NULL);

	ret = run_command_v_opt(args.v, RUN_GIT_CMD);
	strvec_clear(&args);
	return ret;
}

static int run_fast_forward(void)
{
	struct strvec args = STRVEC_INIT;
	int ret;

	strvec_pushl(&args, "fast-forward", "FETCH_HEAD", NULL);

	ret = run_command_v_opt(args.v, RUN_GIT_CMD);
	strvec_clear(&args);
	return ret;
}

int cmd_update(int argc, const char **argv, const char *prefix)
{
	if (!getenv("GIT_REFLOG_ACTION"))
		setenv("GIT_REFLOG_ACTION", "update", 0);

	if (repo_read_index_unmerged(the_repository))
		die_resolve_conflict("update");

	if (file_exists(git_path_merge_head(the_repository)))
		die_conclude_merge();

	if (run_fetch())
		return 1;

	return run_fast_forward();
}
