# git-fc

git-fc is a friendly fork of Git, which means it's a fork that won't deviate
from the mainline; it is more like a branch in Git terms. This branch will move
forward close to Git's mainline, and it could be merged at any point in time,
if the maintainer wished to do so.

git-fc doesn't include experimental code, or half-assed features, so you can
expect the same level of stability as Git's mainline. Also, it doesn't remove
any feature, or do any backwards incompatible changes, so you can replace git
with git-fc and you wouldn't notice the difference. The difference comes in the
extra features, that is all.

## Maintenance

Each release of Git is merged directly into git-fc, so if there's a new feature
in Git, git-fc will get it as well.

Every extra feature is maintained individually in a separate branch, so if you
are interested in a specific feature and don't trust the rest of git-fc, you
can use that branch instead. For example the publish tracking branch feature is
maintained in the 'fc/publish' branch which sits on top of git.git's v1.9.2.
You can grab the specific branch and do whatever you want with it.

## Extra features

### Streamlined remote helpers

`git-remote-hg` and `git-remote-bzr` are remote helpers that allow two-way
communication between Git and Mercurial/Bazaar. They have been proven to be
very reliable and solid, and used by many people. In order to use them in Git
mainline you might need a bit of tinkering.

With git-fc they are installed by default, and in the right way. Plus there are
fixes in the remote helper infraestructure so they always work better than in
Git mainline.

### New 'git update' tool

Everybody has agreed the `git pull` command is broken for most use-cases, which
is why most seasoned Git users avoid it, and it is recommended for new users to
avoid it.

A new tool is necessary for the most common use case, which is fetch all the
updates and update the current branch if possible.

The new `git update` will fast-forward to the latest commit in the remote
branch if there's no divergence (you haven't made extra commits). But if you
have made extra commits you will be told to either merge or rebase, or run `git
update --merge` or `git update --rebase`.

This ensures that new users won't be making merges by mistake.

Additionally, when doing a merge the order of the parents will be reversed, so
it would appear as if you are merging your local branch to the remote one, and
not the other way around like `git pull` does. Everybody has agreed this is a
problem with `git pull`.

### Publish tracking branch

Git mainline doesn't have the greatest support for triangular workflows, a good
solution for that is to introduce a second "upstream" tracking branch which is
for the reverse; the branch you normally push to.

Say you clone a repository (libgit2) in GitHub, then create a branch
(feature-a) and push it to your personal repository, you would want to track
two branches (origin/master), and (mine/feature-a), but Git mainline only
provides support for a single upstream tracking branch.

If you setup your upstream tracking branch to 'origin/master', then you can
just do `git rebase` without arguments and git will pick the right branch
(origin/master) to rebase to. However, `git push` by default will also try to
push to 'origin/master', which is not what you want. Plus `git branch -v` will
show how ahead/behind your branch is compared to origin/master, not
mine/feature-a.

If you set up your upstream to 'mine/feature-a', then `git push` will work, but
`git rebase` won't.

With this option, `git rebase` uses the upstream branch, and `git push` uses
the publish branch.

Setting the upstream tracking branch is easy:

    git push --set-publish mine feature-a

Or:

    git branch --set-publish mine/feature-a

And `git branch -v` will show it as well:

```
  fc/branch/fast      177dcad [master, gh/fc/branch/fast] branch: ...
  fc/stage            abb6ad5 [master, gh/fc/stage] completion: ..
  fc/transport/improv eb4d3c7 [master, gh/fc/transport/improv] ...
```

### Official staging area

Everybody already uses the term "staging area" already, and Git developers also
agreed it the best term to what is officially referred to as "the index". So
git-fc has new options for all commands that modify the staging area (e.g. `git
grep --staged`, `git rm --staged`), and also adds a new `git stage` command
that makes it easier to work with the staging area.

```
'git stage' [options] [--] [<paths>...]
'git stage add' [options] [--] [<paths>...]
'git stage reset' [-q|--patch] [--] [<paths>...]
'git stage diff' [options] [<commit>] [--] [<paths>...]
'git stage rm' [options] [--] [<paths>...]
'git stage apply' [options] [--] [<paths>...]
'git stage edit'
```

Without any command, `git stage` adds files to the stage, same as `git add`, same as in Git mainline.

### Nice 'branch -v'

Currently `git branch -v` will show you the tracking status (ahead/behind), but
wouldn't show you which from which branch, and it takes considerable amount of
time (compared to most Git commands).

This is fixed so the branch is showed instead, which is more useful and faster.
If you want the tracking status, you can use `git branch -vv` which shows
everything, as with Git mainline.

```
  fc/branch/fast      177dcad [master] branch: ...
  fc/stage            abb6ad5 [master] completion: ...
  fc/transport/improv eb4d3c7 [master] transport-helper: ...
```

### Default aliases

Many (if not all) version control system tools have shortcuts for their most
common operations; `hg ci`, `svn co`, `cvs st`, but not Git... git-fc does:

    co = checkout
    ci = commit
    rb = rebase
    st = status
    br = branch
    pi = cherry-pick
    mt = mergetool

If you have already these aliases, or mapped to something else, your aliases
would take precedence over the default ones, so you won't have any problems.

### New core.mode configuration

The behavior of Git v2.0 is already being defined, but there's no way to test
it, if you want to test it, along with all future behaviors, you can enable it
on git-fc by setting the configuration `core.mode = next`.

In addition to the "next" (v2.0) mode, there's the "progress" mode. This mode
enables "next" plus other configurations that are saner.

It is recommended that you setup this mode for git-fc:

    git config --global core.mode progress

### New fetch.default configuration

When you have configured the upstream tracking branch for all your branches,
you will probably have tracking branches that point to a local branch, for
example 'feature-a' pointing to 'master', in which case you would get something
like:

````
% git fetch
From .
 * branch            master     -> FETCH_HEAD
````

Which makes absolutely no sense, since the '.' repository is not even
documented, and FETCH_HEAD is a marginally known concept. In this case `git
fetch` is basically doing nothing from the user's point of view.

So the user can configure `fetch.default = simple` to get a simple sensible
default; `git fetch` will always use 'origin' by default.

If you use the "progress" mode, this option is also enabled.

### Support for Ruby

There is partial optional support for Ruby. Git already has tooling so any
language can use it's plumbing and achieve plenty of tasks:

```ruby
IO.popen(%w[git for-each-ref]) do |io|
  io.each do |line|
    sha1, kind, name = line.split()
    # stuff
  end
end
```

However, this a) requires a process fork, and b) requires I/O communication to
get the desired data. While this is not a big deal on many systems, it is in
Windows systems where forks are slow, and many Git core programs don't work as
well as they do in Linux.

Git has a goal to replace all the core scripts with native C versions, but it's
a goal only in name that is not actually pursued. In addition, that still
leaves out any third party tools since Git doesn't provide a shared libgit
library, which is why an independent libgit2 was needed in the first place.

Ruby bindings solve these problems:

```ruby
for_each_ref() do |name, sha1, flags|
  # stuff
end
```

The command `git ruby` can use this script by providing the bindings for many
Git's internal C functions (though not all), which makes it easier to write
Ruby programs that take full advantage of Git without any need of forks, or I/O
communication.

## Contributions

All these patches were written by me, Felipe Contreras, but contributions from
other people are welcome, as long as they follow these guidelines:

1. Follows Git coding guidelines and is technically correct according to Git
   standards
2. Doesn't break backwards compatibility
3. It doesn't conflict with other Git features so it can be rebased on newer
   versions of Git without much maintenance burden

Patches should be sent using `git send-email` to the mailing list git-fc@googlegroups.com.