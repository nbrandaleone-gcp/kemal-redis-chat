#!/usr/bin/env bash
# watch.sh

# https://crystal-lang.org/2019/04/30/watch-run-change-build-repeat/
# https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md
# brew install watchexec for filesystem watcher

# Use: ./dev/watch.sh awesome_app
# Use: ./dev/watch.sh awesome_app first second

cd $(dirname $0)/..
watchexec -r -w src -- ./dev/build-exec.sh "$@"
