#!/bin/bash

set -e

readonly HERE=$(realpath $(dirname "$0"))

function usage() {
  cat <<EOF
  Usage: $0 [flags]
  Flags:
    -n,--nodocs   Run without building documentation.
    -j,--nojekyll Run without starting a Jekyll server in docker.
    -h,--help     Print this message to stdout.

  This script builds an up-to-date Asylo website and serves it
  incrementally from localhost for quick development iteration.
EOF
}


NO_DOCS=
NO_JEKYLL=
readonly LONG="nodocs,nojekyll,help"
readonly PARSED=$(getopt -o njh --long "${LONG}" -n "$(basename "$0")" -- "$@")
eval set -- "${PARSED}"
while true; do
  case "$1" in
    -n|--nodocs) NO_DOCS=1 ; shift ;;
    -j|--nojekyll) NO_JEKYLL=1; shift ;;
    -h|--help) usage ; exit 0 ;;
    --) shift ; break;;
    *) echo "Unexpected input $1"; usage; exit 1 ;;
  esac
done


function build_proto_file_doc() {
  # Uses protoc-gen-docs from github.com/istio/tools to produce documentation
  # from comments in a .proto file.
  if [[ -z $(which protoc-gen-docs) ]]; then
    echo "Missing the proto documentation compiler protoc-gen-docs." >&2
    return 1
  fi
  
  # TODO: Fix crosslinks.
  local OUT_DIR="$1"
  local SOURCE="$2"
  local CMD="protoc --docs_out=mode=jekyll_html,camel_case_fields=false:${OUT_DIR}"
  local RENAME=$(sed -E 's/^([^.]*)\..*$/\1/' <<< $(basename "${SOURCE}"))

  # This assumes the .proto file is in the asylo package.
  $CMD "${SOURCE}" ; mv "${OUT_DIR}/asylo.pb.html" "${OUT_DIR}/asylo.${RENAME}.v1.html"
}

function build_proto_docs() {
  build_proto_file_doc "$1" asylo/enclave.proto
  build_proto_file_doc "$1" asylo/identity/enclave_assertion_authority_config.proto
  build_proto_file_doc "$1" asylo/identity/identity.proto
  build_proto_file_doc "$1" asylo/identity/identity_acl.proto
  build_proto_file_doc "$1" asylo/identity/sealed_secret.proto
  build_proto_file_doc "$1" asylo/grpc/util/enclave_server.proto
  build_proto_file_doc "$1" asylo/util/status.proto
}


function build_docs() {
  # Build documentation for the website
  SITE="${HERE}/.."  # expects to be in the scripts/ subdirectory.
  BUILD=$(mktemp -d)
  cd "${BUILD}"

  # Fetch the asylo repo for up-to-date documentation.
#  local ARCHIVE="$1"
#  wget -nv "https://github.com/google/asylo/archive/${ARCHIVE}.tar.gz"
#  tar xzf "${ARCHIVE}.tar.gz"
  #  cd "${ARCHIVE}"
  cd /opt/asylo/sdk

  # Build the C++ reference docs.
  rm -rf "${SITE}/doxygen"
  doxygen && cp -r asylo/docs/html/. "${SITE}/doxygen"

  # Build the protobuf documentation.
  build_proto_docs "${SITE}/_docs/reference/proto"
}

if [[ -z "${NO_DOCS}" ]]; then
  # Build documentation for the given Asylo archive.
  # An archive can be either a tag or a commit hash.
  build_docs buildenv-v0.2pre1
fi

if [[ -z "${NO_JEKYLL}" ]]; then
  cd "${HERE}/.."  # Expects to be in scripts/ subdirectory
  # Build and serve the website locally.
  docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll -v $(pwd)/_site:$(pwd)/_site -it -p 4000:4000 jekyll/jekyll:3.6.0 sh -c "bundle install && rake test && bundle exec jekyll serve --incremental --host 0.0.0.0"
fi
