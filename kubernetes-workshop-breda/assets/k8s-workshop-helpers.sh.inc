#!/bin/sh -eu

git_current_branch() {
    printf "%s" "$(git rev-parse --abbrev-ref HEAD)"
}

git_wait_for_change() {
    echo "Polling $(git remote get-url origin) for changes...";
    BRANCH=$(git_current_branch)
    while true; do
        2>&1 git fetch -v --progress origin;
        if [ "$(2>&1 git rev-parse HEAD)" != "$(2>&1 git rev-parse origin/"$BRANCH")" ]; then
            break;
        fi;
        sleep 1;
    done | stdin-spinner;
}

git_current_commit_id() {
    printf "%s" "$(git rev-parse HEAD)"
}

kustomize_set_image_tag_to() {
    TAG="$1"
    kustomize edit set image '*'=:"$TAG";
}
