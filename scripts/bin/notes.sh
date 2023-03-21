#!/usr/bin/env bash

set -o errexit
set -o xtrace
set -o pipefail

DATE=$(date +"%Y_%m_%d_%a_notes")
$EDITOR "$HOME/code/notes/$DATE.md"
