#!/bin/bash

# Usage:
#    $> cd /path/to/repository
#    $> ln -s ../../config/git-hooks/pre-commit.sh .git/hooks/pre-commit
#
################################################################################
# https://github.com/AGWA/git-crypt/issues/45#issuecomment-151985431
# Pre-commit hook to avoid accidentally adding unencrypted files which are
# configured to be encrypted with [git-crypt](https://www.agwa.name/projects/git-crypt/)
# Fix to [Issue #45](https://github.com/AGWA/git-crypt/issues/45)
#
test -d .git-crypt && git-crypt status &>/dev/null
if [[ $? -ne 0 ]]; then
  echo "git-crypt has some warnings"
  git-crypt status -e
  exit 1
fi
