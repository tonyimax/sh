#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

# 不指定--prefix默认安装到/usr/local/lib与/usr/local/include
./Configure --prefix=/Users/dev/Desktop/MAVSDK/build/macos/third_party/install && make && sudo make install
