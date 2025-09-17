#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_MAVSDK_SERVER=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=install/macos -Bbuild/macos -S. && cmake --build build/macos -j8 && cmake --install build/macos --config Debug
