#!/usr/bin/env bash
#*******************************************************************************
# Copyright (c) 2024 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License 2.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-2.0/
# 
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#     IBM Corporation - initial API and implementation
#*******************************************************************************

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
    trap env EXIT
    env
    set -x
fi
# ensure we build the app repo Dockerfile
#cd "$WORKSPACE/$(load_repo app-repo path)"
#source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/build_setup.sh
#source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/build.sh

# Setup Java and report version
export JAVA_HOME=$(pwd)/jdk-21.0.2+13
export PATH=$JAVA_HOME/bin:$PATH
java -version

# Go into OpenLiberty Repo
cd "$WORKSPACE/$(load_repo app-repo path)"

# Recreate our liberty user
useradd -d "$WORKSPACE/liberty" --no-user-group --uid 1500 liberty

# Follow packaging steps from OL Readme.md
cd dev
su liberty -c "./gradlew releaseNeeded"

# # Code To save artifact into known area (WIP)
# # Make sure you connect the built artifact to the repo and commit
# # it was built from. The source repo asset format is:
# #   <repo_URL>.git#<commit_SHA>
# url="$(load_repo app-repo url)"
# sha="$(load_repo app-repo commit)"

# openLibertyImage=$(echo cnf/release/dev/openliberty/*/openliberty-*.zip)
# save_artifact openlibertyimage \
# type=zip \
# "name=openlibertyimage.zip" \
# "location=${openLibertyImage}" \
# "source=${url}.git#${sha}"

# Probably a no-op
$WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/publishFiles.sh