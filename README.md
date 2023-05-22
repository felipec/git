# git-fc

git-fc is a fork of Junio Hamano's git.

git-fc doesn't include experimental code, or half-assed features, so you can
expect the same level of stability as Junio's git. Also, it doesn't remove any
feature, or do any backwards incompatible changes, so you can replace `git` with
`git-fc` and you wouldn't notice any missing feature, only extra features.

## Extra features

### New 'git stage' command

Absolutely everyone in the Git community has agreed that the term "the index"
does not help people understand what it is and how it is used. Everyone except
Junio Hamano.

This is particularly true of newcomers, which is why everyone that teaches git
uses the term "staging area", and that includes tutorials, and even the Pro Git
book.

There is absolutely no reason not to use the term "staging area".

As a first step a new command is introduced: `git stage`.

Junio's git already has a `git stage` command, but it's just an alias for `git
add`.

The new command adds new options, for example:

 * `git stage --remove`
 * `git stage --diff`
 * `git stage --edit`

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
local branch is merged to the remote one, and not the other way around like
`git pull` does. Again: everyone has agreed this is serious a problem with
`git pull` that has no solution except avoiding this command.

Blog post: [git update: the odyssey for a sensible git pull](https://felipec.wordpress.com/2021/07/05/git-update/).

### Publish tracking branch

Junio's git doesn't have the greatest support for triangular workflows. A good
solution for that is to introduce a second "upstream" tracking branch which is
for the reverse: the branch you normally push to.

Say you clone a repository `libgit2` in GitHub, then create a branch
`feature-a` and push it to your personal repository. You would want to track
two branches: `origin/master` and `mine/feature-a`, but Junio's git only
provides support for a **single** upstream tracking branch.

If you setup your upstream tracking branch to `origin/master`, then you can
just do `git rebase` without arguments and git will pick the right branch
(`origin/master`) to rebase to. However, `git push` by default will also try to
push to 'origin/master', which is not what you want. Plus `git branch -v` will
show how ahead/behind your branch is compared to `origin/master`, not
`mine/feature-a`.

If you set up your upstream to `mine/feature-a`, then `git push` will work, but
`git rebase` won't.

With this new publish feature, `git rebase` uses the _upstream_ branch, and
`git push` uses the _publish_ branch.

Setting the upstream tracking branch is easy:

    git push --set-publish mine feature-a

Or:

    git branch --set-publish mine/feature-a

And `git branch -v` will show it as well:

```
  branch/fast      ... [master, gh/branch/fast] ...
  stage            ... [master, gh/stage] ...
  transport/improv ... [master, gh/transport/improv] ...
```

Another advantage of this asymmetry is that `git branch -vv` can show separate
ahead and behind markers, for example behind master (`master<`) and ahead of
mine/feature-a (`mine/feature-a>`).

This is how triangular workflow support should be implemented.

## Other

There's many other improvements that have been accumulating through the years:

 * `fetch.default=sane` fetches a proper default instead of '.'
 * `push.default=simple` is fixed
 * shell completions are much improved

There's many more improvements pending that I implemented in the past, but
haven't had the time to properly port them.

## Contributions

Contributions are welcome on the mailing list git-fc@googlegroups.com.
