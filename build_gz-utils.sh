#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

brew install doxygen &&
git clone https://github.com/gazebosim/gz-utils &&
cd gz-utils; mkdir build; cd build; cmake ../; make doc
