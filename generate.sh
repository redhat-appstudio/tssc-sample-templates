#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# pull in latest pipeline run definition
$ROOTDIR/scripts/update-tekton-definition

# get gitops templates
echo SKIP $ROOTDIR/scripts/import-gitops-template
