#!/bin/bash -u
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

status=$1
test_result_folder=$2

attachments=()

for file in $(cd $test_result_folder; find *.xml -type f) ; do
  attachments+=("--attachment $test_result_folder/$file")
)
done

collect-evidence \
  --tool-type "junit" \
  --status "$status" \
  --evidence-type com.ibm.unit_tests \
  "${attachments[@]}" \
  --asset-type "repo" \
  --asset-key "app-repo"