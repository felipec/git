/*
 * Copyright (C) 2021 Felipe Contreras
 */

#include "builtin.h"
#include "parse-options.h"
#include "run-command.h"
#include "dir.h"

enum update_mode_type {
	UPDATE_MODE_FAST_FORWARD = 0,
	UPDATE_MODE_MERGE
};

static enum update_mode_type mode = UPDATE_MODE_FAST_FORWARD;

static const char * const update_usage[] = {
	N_("git update [<options>]"),
	NULL
};

static struct option update_options[] = {
	OPT_SET_INT_F('f', "ff", &mode,
		N_("incorporate changes by fast-forwarding"),
		UPDATE_MODE_FAST_FORWARD, PARSE_OPT_NONEG),
	OPT_SET_INT_F('m', "merge", &mode,
		N_("incorporate changes by merging"),
		UPDATE_MODE_MERGE, PARSE_OPT_NONEG),

	OPT_END()
};

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

static int run_merge(void)
{
	int ret;
	struct strvec args = STRVEC_INIT;

	strvec_pushl(&args, "merge", "--reverse-parents", "FETCH_HEAD", NULL);

	ret = run_command_v_opt(args.v, RUN_GIT_CMD);
	strvec_clear(&args);
	return ret;
}

int cmd_update(int argc, const char **argv, const char *prefix)
{
	if (!getenv("GIT_REFLOG_ACTION"))
		setenv("GIT_REFLOG_ACTION", "update", 0);

	argc = parse_options(argc, argv, prefix, update_options, update_usage, 0);

	if (repo_read_index_unmerged(the_repository))
		die_resolve_conflict("update");

	if (file_exists(git_path_merge_head(the_repository)))
		die_conclude_merge();

	if (run_fetch())
		return 1;

	if (mode == UPDATE_MODE_FAST_FORWARD)
		return run_fast_forward();
	if (mode == UPDATE_MODE_MERGE)
		return run_merge();

	return 1;
}
