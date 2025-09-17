#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

export ANDROID_API=25
export ANDROID_NDK=/opt/aarch64-linux-android
export ANDROID_NDK_REVISION=r25b
export ANDROID_NDK_ROOT=/opt/aarch64-linux-android
export AR=/opt/aarch64-linux-android/bin/llvm-ar
export AS=/opt/aarch64-linux-android/bin/llvm-as
export CC=/opt/aarch64-linux-android/bin/clang
export CMAKE_TOOLCHAIN_FILE=/opt/aarch64-linux-android/Toolchain.cmake
export CROSS_ROOT=/opt/aarch64-linux-android
export CROSS_TRIPLE=aarch64-linux-android
export CXX=/opt/aarch64-linux-android/bin/clang++
export LD=/opt/aarch64-linux-androidbin/ld
cmake -Bliblzma_build -DCMAKE_ANDROID_STL_TYPE=c++_static -DXZ_NLS=OFF -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../../../install -Sliblzma && cmake --build liblzma_build -j8 && cmake --install liblzma_build 
