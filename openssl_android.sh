export ANDROID_NDK_ROOT=~/Desktop/android-ndk-r25b
PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH 
rm -rf build && mkdir build && cd build && ../Configure android-arm64 -D__ANDROID_API__=23 && make && sudo make install
