#!/bin/bash
set -e; set -o pipefail

# See http://stackoverflow.com/a/4774063.
script_dir=${script_dir:-(cd $(dirname $0); pwd -P)}

source $script_dir/kerndev-functions.sh
source $script_dir/kerndev-defaults.sh
