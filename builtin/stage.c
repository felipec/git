/*
 * Copyright (C) 2013-2023 Felipe Contreras
 */

#include "builtin.h"
#include "parse-options.h"
#include "run-command.h"

static const char *const stage_usage[] = {
	N_("git stage [options] [--] [<pathspec>...]"),
	N_("git stage (-a | --add) [options] [--] [<pathspec>...]"),
	NULL
};

static int rerun(struct child_process *cmd, const char **argv, const char *prefix)
{
	strvec_pushv(&cmd->args, argv);

	cmd->dir = prefix;
	cmd->git_cmd = 1;
	return run_command(cmd);
}

int cmd_stage(int argc, const char **argv, const char *prefix)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	int add = 0;

	struct option options[] = {
		OPT_BOOL_F('a', "add", &add, N_("add changes"), PARSE_OPT_NONEG),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, stage_usage,
		PARSE_OPT_KEEP_UNKNOWN_OPT | PARSE_OPT_KEEP_DASHDASH);

	strvec_push(&cmd.args, "add");

	return rerun(&cmd, argv, prefix);
}
