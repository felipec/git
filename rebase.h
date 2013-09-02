#ifndef REBASE_H
#define REBASE_H

enum rebase_type {
	REBASE_INVALID = -1,
	REBASE_DEFAULT = 0,
	REBASE_FALSE,
	REBASE_TRUE,
	REBASE_PRESERVE,
	REBASE_MERGES,
	REBASE_INTERACTIVE
};

enum rebase_type rebase_parse_value(const char *value);

enum pull_mode_type {
	PULL_MODE_INVALID = -1,
	PULL_MODE_DEFAULT = 0,
	PULL_MODE_MERGE,
	PULL_MODE_REBASE
};

enum pull_mode_type pull_mode_parse_value(const char *value);

#endif /* REBASE */
