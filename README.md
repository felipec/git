# git-fc

git-fc is a fork of Junio Hamano's git.

git-fc doesn't include experimental code, or half-assed features, so you can
expect the same level of stability as git's mainline. Also, it doesn't remove
any feature, or do any backwards incompatible changes, so you can replace git
with git-fc and you wouldn't notice any missing feature, only extra features.

## Extra features

### New 'git stage' command

Absolutely everyone in the Git community has agreed that the term "the index"
does not people understand what it is and how it is used. Everyone except Junio
Hamano.

This is particularly true of newcomers, which is why everyone that teaches git
uses the term "staging area", and that includes tutorials, and even the Pro Git
book.

There is absolutely no reason not to use the term "staging area".

As a first step a new command is introduced: `git stage`.

Junio's git already has a `git stage` command, but it's just an alias for `git
add`.

The new command adds new options, for example:

 * git stage --remove
 * git stage --diff
 * git stage --edit

`git stage --remove` is essentially the same as `git reset --mixed`,
`git stage --diff` is the same as `git diff --cached`, but `git stage --edit` is
something that cannot be achieved in Junio's git: allows you to edit the patch
directly.

Additionally, a new `git unstage` command is introduced, again: the same as
`git reset --mixed`.

Blog post: [The git staging area, the term literally everyone agrees with](https://felipec.wordpress.com/2021/08/10/git-staging-area-rename/).

### New 'git update' command

Everybody has agreed the `git pull` command is broken for most use-cases, which
is why most seasoned git users avoid it, and it is recommended that new users
avoid it as well.

A new command is necessary for the most common use case, which is to fetch all
the updates and advance the current branch if possible.

The new `git update` will fast-forward to the latest commit in the remote
branch if there's no divergence (you haven't made extra commits). But if you
have made extra commits you will be told to do either merge or rebase. This is
the behavior everyone has agreed is the best.

This ensures that new users won't be making merges by mistake.

Additionally, when doing a merge the order of the parents is reversed, so the
local branch is merged to the remote one, and not the other way around like `git
pull` does. Again: everyone has agreed this is serious a problem with `git
pull` that has no solution except not using this command.

Blog post: [git update: the odyssey for a sensible git pull](https://felipec.wordpress.com/2021/07/05/git-update/).

### Pending

A previous instance of git-fc had more features but I've decided to re-start
from scracth, therefore not all the features are available right now. Some of
these are almost ready, others still need a lot more work:

 * Publish branch
 * Default aliases
 * Better branch --list
 * New fetch.default configuration

## Contributions

Contributions are welcome on the mailing list git-fc@googlegroups.com.
