#!/bin/bash -u
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