#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

# iOS禁用idn2与socket库 -DUSE_LIBIDN2=OFF -DHAVE_LIBSOCKET=OFF
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=install/ios -DBUILD_MAVSDK_SERVER=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_TOOLCHAIN_FILE=tools/ios.toolchain.cmake -DPLATFORM=OS -DUSE_LIBIDN2=OFF -DHAVE_LIBSOCKET=OFF -Bbuild/ios -H. && cmake --build build/ios -j8 && cmake --install build/ios --config Debug
