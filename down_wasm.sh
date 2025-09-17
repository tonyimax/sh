#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

DOWNLOAD_DIR="$HOME/Downloads"
TARGET_FILE="wasm-binaries.tar.xz"
TAG="32b8ae819674cb42b8ac2191afeb9571e33ad5e2"
TARGET_DIR="$HOME/Desktop/sh/emsdk_setup/emsdk_deps"

echo "下载路径: $DOWNLOAD_DIR"
echo "文件保存路径: $DOWNLOAD_DIR/$TARGET_FILE"
if [[ -f "$DOWNLOAD_DIR/$TARGET_FILE" ]]; then
    echo "文件 $TARGET_FILE 已存在!"
    cd "$DOWNLOAD_DIR" || exit
    mv $TARGET_FILE $TARGET_DIR/$TAG-$TARGET_FILE
    echo "移动文件$TARGET_FILE 到 $TARGET_DIR/$TAG-$TARGET_FILE 成功!"
else
    echo "file $TARGET_FILE not exists ,download it ..."
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --background "https://storage.googleapis.com/webassembly/emscripten-releases-builds/mac/$TAG/$TARGET_FILE"
    while [[ ! -f "$DOWNLOAD_DIR/$TARGET_FILE" ]]; do
        echo "文件$DOWNLOAD_DIR/$TARGET_FILE 下载中..."
        sleep 2
    done
    echo "文件$TARGET_FILE 下载成功!"
    cd "$DOWNLOAD_DIR" || exit
    mv $TARGET_FILE "$TARGET_DIR"/$TAG-$TARGET_FILE
    echo "移动文件$TARGET_FILE 到 $TARGET_DIR/$TAG-$TARGET_FILE 成功!"
fi


