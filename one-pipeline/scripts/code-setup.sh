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
if [[ "$(get_env pipeline_namespace)" == *"pr"* ||  "$(get_env pipeline_namespace)" == *"ci"* ]]; then
    # Java Setup Code
    curl -L https://github.com/ibmruntimes/semeru21-binaries/releases/download/jdk-21.0.2%2B13_openj9-0.43.0/ibm-semeru-open-jdk_x64_linux_21.0.2_13_openj9-0.43.0.tar.gz --output ibm-semeru-open-jdk_x64_linux_21.0.2_13_openj9-0.43.0.tar.gz
    tar -xvzf ibm-semeru-open-jdk_x64_linux_21.0.2_13_openj9-0.43.0.tar.gz
    export JAVA_HOME=$(pwd)/jdk-21.0.2+13
    export PATH=$JAVA_HOME/bin:$PATH
    java -version
fi
set

# Go into OpenLiberty Repo
cd "$WORKSPACE/$(load_repo app-repo path)"

# Run all the gradle tasks as a separate user to work around
# https://wasrtc.hursley.ibm.com:9443/jazz/web/projects/WS-CD#action=com.ibm.team.workitem.viewWorkItem&id=299296
# Force the home directory to be in the workspace, which is outside the docker container
# so that anything created their (eg gradle cache) persists between steps
# Force the id, so we can be consistent too
# Even without this defects, running as non-root is good practice
useradd -d "$WORKSPACE/liberty" --no-user-group --uid 1500 liberty
chown -R liberty .

# Follow Compilation and unit test steps from OL Readme.md
cd dev
su liberty -c "./gradlew cnf:initialize"
su liberty -c "./gradlew assemble"