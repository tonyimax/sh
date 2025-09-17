#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

git clone https://github.com/openssl/openssl.git --recursive &&
cp openssl_android.sh ./openssl/. && cd openssl && sh ./openssl_android.sh &&
cd .. && git clone https://github.com/mavlink/MAVSDK.git --recursive &&
cp ./third_party_CMakeLists.txt ./MAVSDK/third_party/CMakeLists.txt &&
cp android.sh ./MAVSDK/. && cd MAVSDK && sh ./android.sh 
