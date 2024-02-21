#!/bin/bash -u
#*******************************************************************************
# Copyright (c) 2023 IBM Corporation and others.
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

echo "$(date): Starting copyFileList.sh with parameters:"
echo "Source host: ${source_USER:-$(whoami)}@${sourceHost}"
echo "Target host: ${target_USER:-$(whoami)}@${targetHost}"
echo "File list: $sourceListFile"

if [ ! -f "$sourceListFile" ] ; then
    echo "$sourceListFile not found"
    exit 2
fi

if [ "$(uname)" = "OS/390" ] ; then
    echo "On z/os, converting $sourceListFile to EBCDIC so we can read it"
    /usr/local/bin/a2e "$sourceListFile"
    if [ "$sourceHost" != "localhost" ] ; then
        if [ -f ${source_KEY}.ebcdic ] ; then
            echo "Using cached EBCDIC source key"
        else
            echo "Converting $source_KEY to ebcdic"
            /usr/local/bin/a2e <${source_KEY} >${source_KEY}.ebcdic
            chmod 600 ${source_KEY}.ebcdic
        fi
        export source_KEY=${source_KEY}.ebcdic
    fi
    if [ "$targetHost" != "localhost" ] ; then
        if [ -f ${target_KEY}.ebcdic ] ; then
	    echo "Using cached EBCDIC target key"
        else
            echo "Converting $target_KEY to ebcdic"
            /usr/local/bin/a2e <${target_KEY} >${target_KEY}.ebcdic
            chmod 600 ${target_KEY}.ebcdic
        fi
        export target_KEY=${target_KEY}.ebcdic
    fi
fi
if [ $(grep -c '^[cC]:' "$sourceListFile") -gt 0 ] ; then
    echo "Windows format paths found - converting to cygwin format"
    sed -i -e 's#\\#/#g' -e 's#^[cC]:#/cygdrive/c#' "$sourceListFile"
fi
cat "$sourceListFile"

function downloadFile {
    df_sourceFile=$1
    df_targetFile=$2
    df_sourceDir=$(dirname "${df_sourceFile}")
    df_sourceFileName=$(basename "${df_sourceFile}")
    df_targetDir=$(dirname "${df_targetFile}")
    df_targetFileName=$(basename "${df_targetFile}")
    
    df_retries=0
    df_lastrc=0
    while [ ${df_retries} -lt 10 ] ; do
        sftp -b - -i "${source_KEY}" "${source_USER}@${sourceHost}" <<EOF
cd ${df_sourceDir}
lcd ${df_targetDir}
get -r ${df_sourceFile} ${df_targetFileName}
EOF
        df_lastrc=$?
        if [ ${df_lastrc} -eq 0 ] ; then
            # it worked!
            break
        fi
        df_retries=$((${df_retries}+1))
        echo "$(date): Download failed rc ${df_lastrc}, retry in $((${df_retries}*5)) minutes"
        sleep $((${df_retries}*5))m
    done
    if [ ${df_lastrc} -gt 0 ] ; then
        echo "$(date): FAILED TO DOWNLOAD ${df_sourceFile} from ${sourceHost} to ${df_targetFile} and ran out of retries"
    fi
    return ${df_lastrc}
}

# Create a directory on the target machine.  This is a bit horrible because sftp doesn't allow us to explicitly check what exists
# The logic is:
# 1. Attempt to cd to the directory - if that succeeds then the directory exists and we're all good so return
# 2. Attempt to create the directory - if that succeeds we're all good so return
# 3. Recurse up the directory tree (ie make the parent if it doesn't exist, etc, all the way up to /).  Don't care if this fails, as it might be a timing window
# 4. Retriy making the directory - if that succeeds then we're all good so return
# 5. Retry cd to the directory - it may have been created by somebody else while we were running
function ensureUploadDirectory {
    ed_targetFile=$1
    ed_targetDir=$(dirname "${ed_targetFile}")

    sftp -b - -i "${target_KEY}" "${target_USER}@${targetHost}" <<EOF
cd "${ed_targetDir}"
EOF
    ed_rc=$?
    if [ ${ed_rc} -eq 0 ] ; then
        return 0
    fi

    if [ "${ed_targetDir}" = "/" ] ; then
        echo "$(date): Cannot cd /, we are doomed"
        return ${ed_rc}
    fi
    
    echo "$(date): Creating ${ed_targetDir} on ${target_USER}@${targetHost}"
    sftp -b - -i "${target_KEY}" "${target_USER}@${targetHost}" <<EOF
mkdir "${ed_targetDir}"
EOF
    if [ $? -eq 0 ] ; then
        return 0
    else
        echo "- failed - trying to create parent"
        # the ()s make this run in a subshell, so preventing it overwriting our ed_targetDir variable
        (ensureUploadDirectory ${ed_targetDir})
    fi
    echo "$(date): Creating ${ed_targetDir} on ${target_USER}@${targetHost} again"
    sftp -b - -i "${target_KEY}" "${target_USER}@${targetHost}" <<EOF
mkdir "${ed_targetDir}"
EOF
    rc=$?
    if [ $rc -gt 0 ] ; then
        sftp -b - -i "${target_KEY}" "${target_USER}@${targetHost}" <<EOF
cd "${ed_targetDir}"
EOF
        return $?
    else
        return 0
    fi
}
    
function uploadFile {
    uf_sourceFile=$1
    uf_targetFile=$2

    ensureUploadDirectory "${uf_targetFile}"

    uf_retries=0
    uf_lastrc=0
    uf_sourceDir=$(dirname "${uf_sourceFile}")
    uf_sourceFileName=$(basename "${uf_sourceFile}")
    uf_targetDir=$(dirname "${uf_targetFile}")
    uf_targetFileName=$(basename "${uf_targetFile}")
    while [ ${uf_retries} -lt 10 ] ; do
        sftp -b - -i "${target_KEY}" "${target_USER}@${targetHost}" <<EOF
cd ${uf_targetDir}
lcd ${uf_sourceDir}
put -r ${uf_sourceFileName} ${uf_targetFileName}
EOF
        uf_lastrc=$?
        if [ ${uf_lastrc} -eq 0 ] ; then
            # it worked!
            break
        fi
        uf_retries=$((${uf_retries}+1))
        echo "$(date): Upload failed rc ${uf_lastrc}, retry in $((${uf_retries}*5)) minutes"
        sleep $((${uf_retries}*5))m
    done
    if [ ${uf_lastrc} -gt 0 ] ; then
        echo "$(date): FAILED TO UPLOAD ${uf_sourceFile} to ${uf_targetFile} on ${target_USER}@${targetHost} and ran out of retries"
    fi
    return ${uf_lastrc}
}
    

# Check we have host keys for each host
if [ "$targetHost" != "localhost" ] ; then
    if [ ! -f ~/.ssh/known_hosts ] ; then
        ssh-keyscan "$targetHost" >>~/.ssh/known_hosts
    elif [ $(grep -c "$targetHost" ~/.ssh/known_hosts) -eq 0 ] ; then
        ssh-keyscan "$targetHost" >>~/.ssh/known_hosts
    fi
fi
if [ "$sourceHost" != "localhost" ] ; then
    if [ ! -f ~/.ssh/known_hosts ] ; then
        ssh-keyscan "$sourceHost" >>~/.ssh/known_hosts
    elif [ $(grep -c "$sourceHost" ~/.ssh/known_hosts) -eq 0 ] ; then
        ssh-keyscan "$sourceHost" >>~/.ssh/known_hosts
    fi
fi

# Create a staging area to download files to
mkdir -p "staging" || exit $?
export STAGING="$PWD/staging"

# Loop through the file list, downloading and uploading each in turn
while read line ; do
    # Remove every character that isn't a , and count how many are left
    commaCount=$(echo $line | tr -cd , | wc -c)
    if [ $commaCount = 0 ] ; then
        sourceFile=$line
        targetFile=$line
    elif [ $commaCount = 1 ] ; then
        # Split the line on the comma to get source and target files
        sourceFile="$(echo $line | cut -d , -f 1)"
        targetFile="$(echo $line | cut -d , -f 2)"
    else
        echo "There should be no more than 1 comma on each line in $sourceListFile.  I found $commaCount in line:"
        echo "$line"
        exit 2
    fi

    # Download the source file
    if [ "$sourceHost" = "localhost" ] ; then
        stagingFile="$sourceFile"
    else
        if [ "$targetHost" = "localhost" ] ; then            
            stagingFile="$targetFile"
        else
            stagingFile="${STAGING}/$(basename $sourceFile)"
        fi
        echo "$(date): Downloading $sourceFile on ${sourceHost} to $stagingFile"
        downloadFile "$sourceFile" "$stagingFile" || exit $?
    fi
    
    # Upload it to the target
    if [ "$targetHost" = "localhost" ] ; then
        if [ "$stagingFile" != "$targetFile" ] ; then
            echo "$(date): Copying $sourceFile to $targetFile"
            cp -av "$stagingFile" "$targetFile" || exit $?
        fi
    else
        echo "$(date): Uploading $stagingFile to $targetFile on ${targetHost}"
        uploadFile "$stagingFile" "$targetFile" || exit $?
    fi

    # Tidy up
    if [ "$stagingFile" != "$sourceFile" -a "$stagingFile" != "$targetFile" ] ; then
        rm -rfv "$stagingFile"
    fi
    
done <"${sourceListFile}"
echo "ALL DONE"
rm -rf "${STAGING}" || exit $?

