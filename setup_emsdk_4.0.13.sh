#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

rm -rf ~/emsdk
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
cd ~/emsdk || exit
git pull
export EMSDK_KEEP_DOWNLOADS=1
SCRIPT_DIR=~/Desktop/sh/emsdk_setup
DEPS_DIR=$SCRIPT_DIR/emsdk_deps
DOWNLOAD=~/emsdk/downloads/.
mkdir -p $DEPS_DIR
cd $DEPS_DIR || exit
wget --no-check-certificate https://nodejs.org/dist/v22.19.0/node-v22.19.0-linux-x64.tar.xz
wget --no-check-certificate https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz
rm -rf ../3.13.7_64bit
mkdir -p ../3.13.7_64bit
tar -xvf ./Python-3.13.7.tar.xz -C ../3.13.7_64bit
cd ..
sh down_wasm.sh
cd ..

cd $DEPS_DIR || exit
tar -xvf ./Python-3.13.7.tar.xz && mv ./Python-3.13.7 ./python-3.13.7  && tar -czf python-3.13.7-0-macos-x86_64.tar.gz python-3.13.7 && rm -rf ./python-3.13.7 && ls -l
pwd
cp ./node*.xz $DOWNLOAD
cp ./*.gz $DOWNLOAD
cp ./*-wasm-binaries.tar.xz $DOWNLOAD
cp ./python-3.13.7-0-macos-x86_64.tar.gz $DOWNLOAD
echo "copy gz and xz file ok!"
sleep 2
cd $SCRIPT_DIR || exit
cp ./emsdk    		 ~/emsdk/.
cp ./emsdk.py 		 ~/emsdk/.
cp ./emsdk_manifest.json   ~/emsdk/.
mkdir -p ~/emsdk/python
cp -r ./3.13.7_64bit 	 ~/emsdk/python/.

cd ~/emsdk || exit
./emsdk install sdk-main-64bit
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
echo 'source "/Users/dev/emsdk/emsdk_env.sh"' >> ~/.zshrc

