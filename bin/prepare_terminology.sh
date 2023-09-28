#!/bin/bash
set -e

if [ -n "$1" ]
then
  version="$1"
else
  version="2023"
fi

temp_folder="tmp/terminology/${version}"

echo "Prepare version ${version}"

if [[ ! -f "$temp_folder/umls.zip" ]]; then
  [[ -z "$UMLS_API_KEY" ]] && { echo "UMLS API key environment variable is empty" >&2 ; exit 1; }
  function control_c_download {
    kill -INT "$child"
    rm -f "$temp_folder/umls.zip"
    exit $?
  }
  trap control_c_download SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
  bundle exec rake terminology:download_umls["$UMLS_API_KEY","$version"] &
  child=$!
  wait "$child"
else
  echo "${version} UMLS Zip already exists; skipping UMLS download Rake task."
fi

if [[ ! -e "$temp_folder/umls" ]]; then
  function control_c_unzip {
    kill -INT "$child"
    rm -rf "$temp_folder/umls"
    exit $?
  }
  trap control_c_unzip SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
  bundle exec rake terminology:unzip_umls["$version"] &
  child=$!
  wait "$child"
else
  echo "${version} UMLS Directory already exists; skipping UMLS Unzip Rake task."
fi

if [[ ! -e "$temp_folder/umls_subset" ]]; then
  function control_c_mmsys {
    kill -INT "$child"
    rm -rf "$temp_folder/umls_subset"
    exit $?
  }
  trap control_c_mmsys SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
  bundle exec rake terminology:run_umls["$version"] &
  child=$!
  wait "$child"
else
  echo "${version} UMLS Subset already exists; skipping Metamorphosys Rake task."
fi

# Note: these are unversioned, hence why they don't make use of $temp_folder
if [[ ! -e "tmp/terminology/fhir" ]]; then
  function control_c_packages {
    kill -INT "$child"
    rm -rf "tmp/terminology/fhir"
    exit $?
  }
  trap control_c_packages SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
  bundle exec rake terminology:download_program_terminology &
  child=$!
  wait "$child"
else
  echo "FHIR Package sources already exist; skipping Package download."
fi

if [[ ! -f "$temp_folder/umls.db" ]]; then
  function control_c_db {
    kill -INT "$child"
    rm -f "$temp_folder/umls.db"
    rm -f "$temp_folder/MRCONSO.pipe"
    rm -f "$temp_folder/MRREL.pipe"
    rm -f "$temp_folder/MRSAT.pipe"
    exit $?
  }
  trap control_c_db SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
  ./bin/create_umls.sh $version &
  child=$!
  wait "$child"
else
  echo "${version} UMLS DB Already exists; skipping creation script."
fi

trap - SIGHUP SIGINT SIGTERM SIGQUIT SIGKILL SIGTSTP
