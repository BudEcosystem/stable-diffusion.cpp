#!/usr/bin/env bash
# Moves Gaia's patch stack onto a new upstream release (see GAIA.md).
#
#   gaia/rebase.sh <new-upstream-tag>           rebase branch gaia in place
#   gaia/rebase.sh --check <new-upstream-tag>   trial on a scratch branch: list
#                                               every patch that conflicts, then
#                                               leave gaia exactly as it was
#
# The old base is read from GAIA.md. On a conflict the in-place run stops at the
# patch that conflicted and names it; resolve, `git rebase --continue`, and run
# the script again with the same tag to finish (submodules, GAIA.md base line).
set -euo pipefail

die() {
    echo "rebase.sh: $*" >&2
    exit 1
}

check=0
if [ "${1:-}" = "--check" ]; then
    check=1
    shift
fi
[ $# -eq 1 ] || die "usage: gaia/rebase.sh [--check] <new-upstream-tag>"
new=$1
branch=gaia

root=$(git rev-parse --show-toplevel)
cd "$root"

base_of() {
    sed -n 's/^Upstream base: `\(.*\)`$/\1/p' GAIA.md
}

rebasing() {
    [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]
}

conflicted_patch() {
    git log -1 --format='%h %s' REBASE_HEAD
}

verify_submodules() {
    git submodule update --init --recursive --quiet
    local bad
    bad=$(git submodule status --recursive | grep -v '^ ' || true)
    if [ -n "$bad" ]; then
        echo "$bad" >&2
        die "submodules are not checked out at their pinned commits"
    fi
    # Gaia's patches never move a submodule: the pins must equal upstream's.
    local moved
    moved=$(git diff --name-only "$new" HEAD -- $(git config -f .gitmodules --get-regexp '\.path$' | awk '{print $2}'))
    [ -z "$moved" ] || die "a patch moved submodule pins: $moved"
    echo "submodules: initialised and pinned as $new pins them"
}

if rebasing; then
    die "a rebase is in progress (patch $(conflicted_patch)); resolve it and run 'git rebase --continue' first"
fi
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "the working tree has uncommitted changes"

old=$(git show "$branch:GAIA.md" | sed -n 's/^Upstream base: `\(.*\)`$/\1/p')
[ -n "$old" ] || die "GAIA.md on $branch names no upstream base"

if [ "${GAIA_REBASE_NO_FETCH:-0}" != "1" ]; then
    git fetch --quiet upstream --tags
fi
git rev-parse -q --verify "refs/tags/$new^{commit}" >/dev/null || die "no upstream tag $new"
git rev-parse -q --verify "refs/tags/$old^{commit}" >/dev/null || die "no upstream tag $old (the base GAIA.md names)"

if [ "$old" = "$new" ]; then
    # A finished in-place rebase run again: only the bookkeeping is left.
    git checkout --quiet "$branch"
    verify_submodules
    echo "gaia already stands on $new"
    exit 0
fi

if git merge-base --is-ancestor "$new" "$branch" && [ "$check" -eq 0 ]; then
    # The rebase was finished by hand after a conflict: record the new base.
    git checkout --quiet "$branch"
    verify_submodules
else
    work=$branch
    if [ "$check" -eq 1 ]; then
        work="gaia-rebase-check-$new"
        git branch -f "$work" "$branch"
    fi
    git checkout --quiet "$work"
    echo "rebasing $(git rev-list --count "$old..$branch") commits of $branch from $old onto $new"
    conflicts=()
    if ! git rebase --quiet --onto "$new" "$old" "$work" >/dev/null 2>&1; then
        while rebasing; do
            patch=$(conflicted_patch)
            files=$(git diff --name-only --diff-filter=U | tr '\n' ' ')
            echo "CONFLICT: $patch"
            echo "  files: $files"
            if [ "$check" -eq 0 ]; then
                echo "resolve the files, 'git add' them, 'git rebase --continue', then run: gaia/rebase.sh $new"
                exit 2
            fi
            conflicts+=("$patch")
            git rebase --skip >/dev/null 2>&1 || true
        done
    fi
    if [ "$check" -eq 1 ]; then
        echo "applied on $new:"
        git log --reverse --format='  %h %s' "$new..$work"
        git checkout --quiet "$branch"
        git submodule update --init --recursive --quiet
        git branch -D --quiet "$work"
        if [ ${#conflicts[@]} -eq 0 ]; then
            echo "check: every patch applies cleanly onto $new"
            exit 0
        fi
        echo "check: ${#conflicts[@]} patch(es) conflict onto $new:"
        printf '  %s\n' "${conflicts[@]}"
        exit 2
    fi
    verify_submodules
fi

if [ "$(base_of)" != "$new" ]; then
    sed -i "s/^Upstream base: \`.*\`$/Upstream base: \`$new\`/" GAIA.md
    git commit --quiet -m "gaia: move the upstream base to $new" GAIA.md
fi
echo "gaia now stands on $new:"
git log --reverse --format='  %h %s' "$new..$branch"
echo "next: build, test, then tag gaia-$new-1 (see GAIA.md)"
