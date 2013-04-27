/*
 * Copyright (C) 2013-2023 Felipe Contreras
 */

#include "builtin.h"
#include "parse-options.h"

static const char *const stage_usage[] = {
	N_("git stage [options] [--] [<pathspec>...]"),
	NULL
};

int cmd_stage(int argc, const char **argv, const char *prefix)
{
	struct option options[] = {
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, stage_usage,
		PARSE_OPT_KEEP_ARGV0 | PARSE_OPT_KEEP_UNKNOWN_OPT | PARSE_OPT_KEEP_DASHDASH);

	return cmd_add(argc, argv, prefix);
}
