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
# ensure we're located in the source app repo
#cd "$WORKSPACE/$(load_repo app-repo path)"
#source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/scripts/run_test.sh
#save_deployment_artifact deployment_iks.yml IKS
#save_deployment_artifact deployment_os.yml OPENSHIFT
#run_test test com.ibm.unit_tests unit-test-result.xml 1
# Setup Java and report version
export JAVA_HOME=$(pwd)/jdk-21.0.2+13
export PATH=$JAVA_HOME/bin:$PATH
java -version
set

# Create a copy of the compiled code in which to run the unit tests
cd "$WORKSPACE/"
cp -a "$(load_repo app-repo path)" "unit_tests"

# Run the unit tests as a separate user to work around
# https://wasrtc.hursley.ibm.com:9443/jazz/web/projects/WS-CD#action=com.ibm.team.workitem.viewWorkItem&id=299296
# This also works around issues running the packaging steps in a separate container at the same time
# Force the id, so we can be consistent too
useradd --no-user-group --uid 1500 liberty
chown -R liberty unit_tests

# Follow unit test steps from OL Readme.md
cd unit_tests/dev
su liberty -c "./gradlew test --continue"
testRC=$?
status="success"
if [ "$testRC" != "0" ]; then
    status="failure"
fi

# Publish the unit test results into the evidence store
$WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/publishUnitTestEvidence.sh $status published_outputs/files

# Publish the unit test results back to cognitive
$WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/publishFiles.sh

exit $testRC
