/*
 * Copyright (C) 2021 Felipe Contreras
 */

#include "builtin.h"
#include "parse-options.h"
#include "run-command.h"
#include "config.h"
#include "dir.h"

enum update_mode_type {
	UPDATE_MODE_INVALID = -1,
	UPDATE_MODE_FAST_FORWARD = 0,
	UPDATE_MODE_MERGE,
	UPDATE_MODE_REBASE
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
	OPT_SET_INT_F('r', "rebase", &mode,
		N_("incorporate changes by rebasing"),
		UPDATE_MODE_REBASE, PARSE_OPT_NONEG),

	OPT_END()
};

static enum update_mode_type update_mode_parse_value(const char *value)
{
	if (!strcmp(value, "fast-forward"))
		return UPDATE_MODE_FAST_FORWARD;
	if (!strcmp(value, "merge"))
		return UPDATE_MODE_MERGE;
	if (!strcmp(value, "rebase"))
		return UPDATE_MODE_REBASE;

	return UPDATE_MODE_INVALID;
}

static int git_update_config(const char *var, const char *value, void *cb)
{
	if (!strcmp(var, "update.mode")) {
		mode = update_mode_parse_value(value);
		return 0;
	}

	return git_default_config(var, value, cb);
}

int cmd_update(int argc, const char **argv, const char *prefix)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	cmd.git_cmd = 1;

	if (!getenv("GIT_REFLOG_ACTION"))
		setenv("GIT_REFLOG_ACTION", "update", 0);

	git_config(git_update_config, NULL);

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
		strvec_pushl(&cmd.args, "merge", "--reverse-parents", "FETCH_HEAD", NULL);
		break;
	case UPDATE_MODE_REBASE:
		strvec_pushl(&cmd.args, "rebase", "FETCH_HEAD", NULL);
		break;
	default:
		return 1;
	}

	return run_command(&cmd);
}
