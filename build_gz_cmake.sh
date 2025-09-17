#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

git clone https://github.com/gazebosim/gz-cmake
cd gz-cmake &&
mkdir build &&
cd build &&
cmake .. -DCMAKE_BUILD_TYPE=Debug && 
#-DCMAKE_INSTALL_PREFIX=~/Desktop/libs/gz-cmake &&
make -j8 && make install
