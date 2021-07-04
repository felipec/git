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

int cmd_update(int argc, const char **argv, const char *prefix)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	cmd.git_cmd = 1;

	if (!getenv("GIT_REFLOG_ACTION"))
		setenv("GIT_REFLOG_ACTION", "update", 0);

	argc = parse_options(argc, argv, prefix, update_options, update_usage, 0);

	if (repo_read_index_unmerged(the_repository))
		die_resolve_conflict("update");

	if (file_exists(git_path_merge_head(the_repository)))
		die_conclude_merge();

	strvec_pushl(&cmd.args, "fetch", "--update-head-ok", NULL);
	if (run_command(&cmd))
		return 1;

	strvec_clear(&cmd.args);

	switch (mode) {
	case UPDATE_MODE_FAST_FORWARD:
		strvec_pushl(&cmd.args, "fast-forward", "FETCH_HEAD", NULL);
		break;
	case UPDATE_MODE_MERGE:
		strvec_pushl(&cmd.args, "merge", "FETCH_HEAD", NULL);
		break;
	default:
		return 1;
	}

	return run_command(&cmd);
}
