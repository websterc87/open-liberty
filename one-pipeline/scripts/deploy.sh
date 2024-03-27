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
set
# source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/deploy_setup.sh
# source $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/deploy.sh

cd "$WORKSPACE/$(load_repo app-repo path)/dev"

# Zip every file in cnf release as this is needed by subsequent pipelines
mkdir published_outputs/files
zip -r published_outputs/files/openlibertyrelease cnf/release/*

# Create CIArtifactUploaded event
mkdir -p published_outputs/events/rawCIArtifacts
cat >published_outputs/events/rawCIArtifacts/openlibertyrelease.properties <<EOF
event=CIArtifactUploaded
description=Maven Repo Output from OL Compilation
category=Artifacts
error=false
path=openlibertyrelease.zip
EOF

# Seperately upload the open liberty image
openLibertyImage=$(echo cnf/release/dev/openliberty/*/openliberty-*.zip)
echo "Found openLibertyImage ${openLibertyImage}"
ln -s "$PWD/${openLibertyImage}" published_outputs/files/openlibertyimage.zip

cat >published_outputs/events/rawCIArtifacts/openlibertyimage.properties <<EOF
event=ProductImageUploaded
imageType=openlibertyimage.zip
description=Open Liberty Zipped Image
path=openlibertyimage.zip
EOF
# Publish the artifacts back to cognitive
$WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/publishFiles.sh