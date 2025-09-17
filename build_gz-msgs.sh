#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

git clone https://github.com/gazebosim/gz-msgs.git --recursive && cd gz-msgs && mkdir build && cd build && cmake ../ && cmake --install .
