#!/usr/bin/env bash

set -e

RUST_TARGET=$1
shift
if [ -z "$RUST_TARGET" ]; then
    echo "Need a rust target"
    exit 1
fi


TARGET_OS=linux
CROSS_BUILD_TARGET=""
APP_DIR="target/${RUST_TARGET}/release/"

CROSS_BUILD_TARGET="--target=${RUST_TARGET}"
rustup target add "${RUST_TARGET}"

if [ "$RUST_TARGET" == "x86_64-unknown-linux-musl" ];then
    UNWIND_ARG="--features unwind"
else
    UNWIND_ARG=""
fi

for b in "$@"; do
    set -x
    cargo build $CROSS_BUILD_TARGET --bin $b --release $UNWIND_ARG
    OUTPUT_ASSET_NAME="${b}-${RUST_TARGET}"
    ls $APP_DIR
    cp $APP_DIR/$b $OUTPUT_ASSET_NAME
    GENERATED_SHA_256=$(shasum -a 256 $OUTPUT_ASSET_NAME | awk '{print $1}')
    echo $GENERATED_SHA_256 > ${OUTPUT_ASSET_NAME}.sha256
    tag_name="${GITHUB_REF##*/}"
    gh release upload "$tag_name" $OUTPUT_ASSET_NAME ${OUTPUT_ASSET_NAME}.sha256
done
