#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

export ANDROID_NDK_ROOT=~/Android/sdk/ndk/25.1.8937393
PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
rm -rf openssl_build && mkdir openssl_build && cd openssl_build && ../openssl/Configure android-arm64 -D__ANDROID_API__=26 --prefix=/Users/dev/Desktop/MAVSDK/build/android/third_party/install && make && make install
