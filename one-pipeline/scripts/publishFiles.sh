#!/bin/bash -eu
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

# Copy files to libertyfs
export sourceHost=localhost
export targetHost=libertyfs.hursley.ibm.com
export targetPrefix=/liberty/personal/im/one-pipeline/${PIPELINE_RUN_ID}/
export sourceListFile=/tmp/fileList.txt
export target_USER=contbldscp
export target_KEY=~/.ssh/contbldscp_id_rsa

if [ -d ~/.ssh ] ; then
    echo "~/.ssh already exists"
else
    echo "Creating ~/.ssh"
    mkdir ~/.ssh
    chmod 700 ~/.ssh
fi
if [ -f ${target_KEY} ] ; then
    echo "${target_KEY} already exists"
else
    echo "Creating ${target_KEY} from secrets manager"
    get_env LibertyFS_SSH > ${target_KEY}
    chmod 600 ${target_KEY}
fi
touch ${sourceListFile}

if [ -d published_outputs/files ] ; then
    cd published_outputs/files
    for file in $(find * -type f) ; do
        echo "${file},${targetPrefix}/${file}" >> ${sourceListFile}
    done
    $WORKSPACE/$PIPELINE_CONFIG_REPO_PATH/one-pipeline/scripts/copyFileList.sh
    rm ${sourceListFile}
    # Move the sent files 
    for file in $(find * -type f) ; do
        [ -d ../sent_flies/$(dirname $file) ] || mkdir -p ../sent_files/$(dirname $file)
        mv $file ../sent_files/$file
    done
    cd -
else
    echo "No new files to publish"
fi

if [ -d published_outputs/events ] ; then
    cd published_outputs/events
    for file in $(find * -name \*.properties) ; do
        # the events are in files called <topic>/<event>.properties
        topic=$(echo $file | cut -d / -f 1)
        # add the missing properties to each file
        aggregationId="OnePipeline|${PIPELINE_ID}|${PIPELINE_RUN_ID}"
        executionId=${aggregationId}-${TASK_NAME}-${STEP_NAME}
        reportingJVMVersion=jdk-21.0.2+13
        reportingOs=SPSContainer
        cat >>$file <<EOF
executionID=${executionId}
aggregationID=${aggregationId}
v1ReleaseBuildUUID=${aggregationId}
v1ReleaseBuildType=${PIPELINE_NAME}
v1ReportingJVM=${reportingJVMVersion}
v1ReportingOS=${reportingOs}
urlPrefix=https://${targetHost}${targetPrefix}
EOF
        echo "Sending event to https://libh-proxy1.fyre.ibm.com/propertyPublish/$topic :"
        cat $file
        curl -X POST --insecure https://libh-proxy1.fyre.ibm.com/propertyPublish/$topic --data @$file
        # Move the event into sent_events so we don't attempt to send it again later
        [ -d ../sent_events/$(dirname $file) ] || mkdir -p ../sent_events/$(dirname $file)
        mv $file ../sent_events/$file
    done
    cd -
else
    echo "No new events to post"
fi
