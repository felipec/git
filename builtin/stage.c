/*
 * Copyright (C) 2013-2023 Felipe Contreras
 */

#include "builtin.h"
#include "parse-options.h"
#include "run-command.h"
#include "diff.h"
#include "diffcore.h"
#include "revision.h"

static const char *const stage_usage[] = {
	N_("git stage [options] [--] [<pathspec>...]"),
	N_("git stage (-a | --add) [options] [--] [<pathspec>...]"),
	N_("git stage (-r | --remove) [options] [--] [<pathspec>...]"),
	N_("git stage (-d | --diff) [options] [<commit>] [--] [<pathspec>...]"),
	N_("git stage (-e | --edit)"),
	NULL
};

static const char *const unstage_usage[] = {
	N_("git unstage [options] [--] [<pathspec>...]"),
	NULL
};

static int rerun(struct child_process *cmd, const char **argv, const char *prefix)
{
	strvec_pushv(&cmd->args, argv);

	cmd->dir = prefix;
	cmd->git_cmd = 1;
	return run_command(cmd);
}

static int run_commandl(const char *prefix, ...)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	va_list ap;
	const char *arg;

	va_start(ap, prefix);
	while ((arg = va_arg(ap, const char *)))
		strvec_push(&cmd.args, arg);
	va_end(ap);

	cmd.dir = prefix;
	cmd.git_cmd = 1;
	return run_command(&cmd);
}

static int do_reset(const char *prefix)
{
	return run_commandl(prefix, "reset", "--quiet", NULL);
}

static int do_apply(const char *file, const char *prefix)
{
	return run_commandl(prefix, "apply", "--recount", "--cached", file, NULL);
}

static int run_edit(int argc, const char **argv, const char *prefix)
{
	char *file = git_pathdup("STAGE_EDIT.patch");
	int out;
	struct rev_info rev;
	int ret = 0;
	struct stat st;

	repo_read_index(the_repository);

	repo_init_revisions(the_repository, &rev, prefix);
	rev.diffopt.context = 7;

	argc = setup_revisions(argc, argv, &rev, NULL);
	add_head_to_pending(&rev);
	if (!rev.pending.nr) {
		struct tree *tree;
		tree = lookup_tree(the_repository, the_repository->hash_algo->empty_tree);
		add_pending_object(&rev, &tree->object, "HEAD");
	}

	rev.diffopt.output_format = DIFF_FORMAT_PATCH;
	rev.diffopt.use_color = 0;
	rev.diffopt.flags.ignore_dirty_submodules = 1;

	out = xopen(file, O_CREAT | O_WRONLY, 0666);
	rev.diffopt.file = xfdopen(out, "w");
	rev.diffopt.close_file = 1;

	if (run_diff_index(&rev, DIFF_INDEX_CACHED))
		die(_("Could not write patch"));
	if (launch_editor(file, NULL, NULL))
		exit(1);

	if (stat(file, &st))
		die_errno(_("Could not stat '%s'"), file);

	ret = do_reset(prefix);
	if (ret)
		goto leave;

	if (!st.st_size)
		goto leave;

	ret = do_apply(file, prefix);
	if (ret)
		goto leave;

leave:
	unlink(file);
	free(file);
	return ret;
}

int cmd_stage(int argc, const char **argv, const char *prefix)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	int add = 0, remove = 0, diff = 0, edit = 0;

	struct option options[] = {
		OPT_BOOL_F('a', "add", &add, N_("add changes"), PARSE_OPT_NONEG),
		OPT_BOOL_F('r', "remove", &remove, N_("remove changes"), PARSE_OPT_NONEG),
		OPT_BOOL_F('d', "diff", &diff, N_("show changes"), PARSE_OPT_NONEG),
		OPT_BOOL_F('e', "edit", &edit, N_("edit changes"), PARSE_OPT_NONEG),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, stage_usage,
		PARSE_OPT_KEEP_UNKNOWN_OPT | PARSE_OPT_KEEP_DASHDASH);

	if (remove)
		strvec_push(&cmd.args, "reset");
	else if (diff)
		strvec_pushl(&cmd.args, "diff", "--staged", NULL);
	else if (edit)
		return run_edit(argc, argv, prefix);
	else
		strvec_push(&cmd.args, "add");

	return rerun(&cmd, argv, prefix);
}

int cmd_unstage(int argc, const char **argv, const char *prefix)
{
	struct child_process cmd = CHILD_PROCESS_INIT;
	struct option options[] = { OPT_END() };

	argc = parse_options(argc, argv, prefix, options, unstage_usage,
		PARSE_OPT_KEEP_UNKNOWN_OPT | PARSE_OPT_KEEP_DASHDASH);

	strvec_push(&cmd.args, "reset");

	return rerun(&cmd, argv, prefix);
}
