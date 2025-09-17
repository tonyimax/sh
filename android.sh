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
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_MAVSDK_SERVER=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=install/android -Bbuild/android -S. && cmake --build build/android -j8 && cmake --install build/android --config Debug
