# git-fc

git-fc is a friendly fork of git, which means it's a fork that won't deviate
from the mainline; it is more like a branch in git terms. This branch will move
forward close to git's mainline, and it could be merged at any point in time,
if the maintainer wished to do so.

git-fc doesn't include experimental code, or half-assed features, so you can
expect the same level of stability as git's mainline. Also, it doesn't remove
any feature, or do any backwards incompatible changes, so you can replace git
with git-fc and you wouldn't notice any missing feature, only extra features.

## Maintenance

Each release of git is merged directly into git-fc, so if there's a new feature
in git, git-fc will get it as well.

Every extra feature is maintained individually in a separate branch, so if you
are interested in a specific feature and don't trust the rest of git-fc, you can
use that branch instead. For example the publish branch feature is maintained in
the 'fc/publish' branch which sits on top of git.git's v2.32. You can grab the
specific branch and do whatever you want with it.

## Extra features

### New 'git update' command

Everybody has agreed the `git pull` command is broken for most use-cases, which
is why most seasoned git users avoid it, and it is recommended that new users to
avoid it as well.

A new command is necessary for the most common use case, which is fetch all the
updates and advance the current branch if possible.

The new `git update` will fast-forward to the latest commit in the remote
branch if there's no divergence (you haven't made extra commits). But if you
have made extra commits you will be told to do either merge or rebase. This is
the behavior everyone has agreed is the best.

This ensures that new users won't be making merges by mistake.

Additionally, when doing a merge the order of the parents is be reversed, so
it would appear as if you are merging your local branch to the remote one, and
not the other way around like `git pull` does. Again, everyone has agreed this
is serious a problem with `git pull`.

Blog post: [git update: the odyssey for a sensible git pull](https://felipec.wordpress.com/2021/07/05/git-update/).

### Pending

A previous instance of git-fc had more features but I've decided to re-start
from scracth, therefore not all the features are available right now. Some of
these are almost ready, others still need a lot more work:

* Publish branch
* Default aliases
* Official staging area
* Better branch --list
* New fetch.default configuration

## Contributions

Contributions are welcome on the mailing list git-fc@googlegroups.com.
