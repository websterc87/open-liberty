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

# Run the compilation steps from OL README.md
# This is done as root, because several of the compliance scans fail if not
cd dev
./gradlew cnf:initialize
initRC=$?
if [ "$initRC" != "0" ]; then
    exit $initRC
fi

./gradlew assemble
assembleRC=$?
exit $assembleRC
