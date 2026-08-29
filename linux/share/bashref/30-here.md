# This machine, specifically

    SUPER+RETURN      new terminal
    SUPER+B           this reference
    SUPER+Q           web search
    SUPER+SPACE       launcher  (type ?? for a web search)
    SUPER+H           voice to text

    omarchy commands              every omarchy command, with summaries
    omarchy menu keybindings --print   every keybinding currently bound
    omarchy update                update the system

# Git, the five you actually use

    git status                what's changed
    git diff                  ...show me exactly what changed
    git add -A                stage everything
    git commit -m "message"   commit it
    git push                  send it up

    git log --oneline -10     last 10 commits, one line each

# Commit hashes — what 0987676 is

Every commit is a snapshot of the whole repo, named by a hash computed FROM
its contents. The full name is 40 hex characters; the first 7 are enough:

    09876766efee1a68a49f22b9f54e579cec131c4f     the real name
    0987676                                      what you actually type

Because the name comes from the content, nothing can be edited or reordered
without changing it. That is what makes the history trustworthy.

    git show 0987676            what changed in that commit, and why
    git diff 0987676 HEAD       everything that changed since then
    git show 0987676:Home.md    Home.md exactly as it was at that moment

`HEAD` means "the latest commit", so `git show HEAD:file` is the same move
against the most recent one. That is the vault's recovery protocol when a
file reads as blank:

    git show HEAD:"Next Steps.MD"

A hash lets you reach any specific commit instead of just the last one.

# Reading a path

    /home/honeyspoons/Projects/changelog-site/index.html
    └─ absolute: starts at /, the root of everything

    ~/Projects/changelog-site       ~ = /home/honeyspoons
    ./index.html                    . = the folder you're standing in
    ../fonts                        .. = one folder up

# When you don't know

    man ls           the manual for a command   (q to quit)
    ls --help        the short version, usually enough
    which python3    where does this command actually live
    type cd          is it a real program, or a shell builtin?
