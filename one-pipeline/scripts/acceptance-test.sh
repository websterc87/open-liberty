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
# export APP_URL=$(get_env app-url)
# source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/run_test.sh    
# run_test acceptance-test com.ibm.acceptance_tests acceptance-test-result.xml 0
# Setup Java and report version
export JAVA_HOME=$(pwd)/jdk-21.0.2+13
export PATH=$JAVA_HOME/bin:$PATH
java -version

# Go into OpenLiberty Repo
cd "$WORKSPACE/$(load_repo app-repo path)"

# Recreate our liberty user
#useradd -d "$WORKSPACE/liberty" --no-user-group --uid 1500 liberty

# Run example fat for now
# TODO: THis should instead wait for the external ci-orchestrator pipeline to complete the fats
#cd dev
#su liberty -c "./gradlew build.example_fat:buildandrun"
cd dev
./gradlew build.example_fat:buildandrun

# Publish the FAT test results back to cognitive
$WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/publishFiles.sh
