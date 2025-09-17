#!/bin/bash

# 作者林宏权 email: lin_hong_quan_msn@hotmail.com
# CSDN: https://blog.csdn.net/fittec?type=blog

#git clone https://code.videolan.org/videolan/x264.git x264
#git clone https://bitbucket.org/multicoreware/x265_git.git x265

NDK=$ANDROID_NDK_HOME
API=28
HOST_TAG="darwin-x86_64"
ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")
X264_SOURCE_DIR="$HOME/Desktop/x264"
X265_SOURCE_DIR="$HOME/Desktop/x265/source"
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG

rm -rf "$HOME/Desktop/android_x26*"
cp "$TOOLCHAIN/bin/llvm-strings" "$TOOLCHAIN/bin/armv7a-linux-androideabi-strings"
cp "$TOOLCHAIN/bin/llvm-strip" "$TOOLCHAIN/bin/armv7a-linux-androideabi-strip"
cp "$TOOLCHAIN/bin/llvm-ranlib" "$TOOLCHAIN/bin/armv7a-linux-androideabi-ranlib"
cp "$TOOLCHAIN/bin/llvm-ar" "$TOOLCHAIN/bin/armv7a-linux-androideabi-ar"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_environment() {
    print_info "检查编译环境..."

    if [ -z "$NDK" ] || [ ! -d "$NDK" ]; then
        print_error "ANDROID_NDK_HOME 未设置或路径不存在"
        print_error "请执行: export ANDROID_NDK_HOME=/path/to/your/ndk"
        exit 1
    fi

    if [ ! -d "$TOOLCHAIN" ]; then
        print_error "工具链路径不存在: $TOOLCHAIN"
        print_error "请检查 NDK 版本和 HOST_TAG 设置"
        exit 1
    fi

    if [ ! -f "$TOOLCHAIN/bin/aarch64-linux-android$API-clang" ]; then
        print_error "未找到编译器，请检查 NDK 路径: $TOOLCHAIN/bin/"
        exit 1
    fi

    if [ ! -d "$X264_SOURCE_DIR" ]; then
        print_error "x264 源码目录不存在: $X264_SOURCE_DIR"
        exit 1
    fi

    if [ ! -d "$X265_SOURCE_DIR" ]; then
        print_error "x265 源码目录不存在: $X265_SOURCE_DIR"
        exit 1
    fi

    if ! command -v cmake &> /dev/null; then
        print_error "未找到 cmake，请安装: brew install cmake"
        exit 1
    fi

    if ! command -v make &> /dev/null; then
        print_error "未找到 make，请安装 Xcode 命令行工具: xcode-select --install"
        exit 1
    fi

    print_success "环境检查通过"
    print_info "NDK 路径: $NDK"
    print_info "工具链路径: $TOOLCHAIN"
}

build_x264() {
    local ARCH=$1
    local PREFIX="$X264_SOURCE_DIR/../android_x264_install/$ARCH"
    print_info "开始编译 x264 for $ARCH"

    cd "$X264_SOURCE_DIR" || return 1

    case "$ARCH" in
        armeabi-v7a)
            TARGET=armv7a-linux-androideabi
            EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
            EXTRA_LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"
            ;;
        arm64-v8a)
            TARGET=aarch64-linux-android
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS=""
            ;;
        x86_64)
            TARGET=x86_64-linux-android
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS=""
            ;;
        *)
            print_error "不支持的架构: $ARCH"
            return 1
            ;;
    esac

    CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
    AR="$TOOLCHAIN/bin/llvm-ar"
    STRIP="$TOOLCHAIN/bin/llvm-strip"
    STRINGS="$TOOLCHAIN/bin/llvm-strings"
    RANLIB="$TOOLCHAIN/bin/llvm-ranlib"

    if [ ! -f "$CC" ]; then
        print_error "编译器不存在: $CC"
        return 1
    fi

    print_info "使用编译器: $CC"

    make distclean 2>/dev/null || make clean 2>/dev/null

    cd $X264_SOURCE_DIR || return 1
    CC="$CC" \
    ./configure \
        --cross-prefix="$TOOLCHAIN/bin/$TARGET-" \
        --sysroot="$TOOLCHAIN/sysroot" \
        --host="$TARGET" \
        --prefix="$PREFIX" \
        --enable-shared \
        --enable-static \
        --enable-pic \
        --disable-cli \
        --disable-asm \
        --extra-cflags="$EXTRA_CFLAGS -Os -fPIC -I$TOOLCHAIN/sysroot/usr/include" \
        --extra-ldflags="$EXTRA_LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"

    if [ $? -ne 0 ]; then
        print_error "x264 configure 失败 for $ARCH"
        return 1
    fi

    # 编译和安装
    make -j$(sysctl -n hw.ncpu)
    if [ $? -ne 0 ]; then
        print_error "x264 编译失败 for $ARCH"
        return 1
    fi

    make install
    if [ $? -ne 0 ]; then
        print_error "x264 安装失败 for $ARCH"
        return 1
    fi

    print_success "x264 for $ARCH 编译完成"
    return 0
}

build_x265() {
    local ARCH=$1
    local PREFIX="$X265_SOURCE_DIR/../../android_x265_install/$ARCH"
    local BUILD_DIR="$X265_SOURCE_DIR/../../android_x265_build/$ARCH"

    print_info "开始编译 x265 for $ARCH"

    export CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
    export CXX="$TOOLCHAIN/bin/${TARGET}${API}-clang++"
    export AR="$TOOLCHAIN/bin/llvm-ar"
    export STRIP="$TOOLCHAIN/bin/llvm-strip"
    export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"

    ANDROID_CFLAGS="-D__ANDROID__ -Os -fPIC -I$SYSROOT/usr/include"
    ANDROID_LDFLAGS="-L$SYSROOT/usr/lib/$TARGET/$API -llog -landroid"

    print_info "使用编译器: $CC"
    print_info "编译标志: $ANDROID_CFLAGS"
    print_info "链接标志: $ANDROID_LDFLAGS"

    cmake -S $X265_SOURCE_DIR -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ARCH" \
        -DANDROID_PLATFORM="android-$API" \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_SYSTEM_VERSION=$API \
        -DCMAKE_ANDROID_ARCH_ABI="$ARCH" \
        -DCMAKE_ANDROID_NDK="$NDK" \
        -DCMAKE_ANDROID_STL_TYPE=c++_static \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_SHARED=ON \
        -DENABLE_CLI=OFF \
        -DENABLE_ASSEMBLY=OFF \
        -DCMAKE_C_FLAGS="$ANDROID_CFLAGS" \
        -DCMAKE_CXX_FLAGS="$ANDROID_CFLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$ANDROID_LDFLAGS" \
        -DCMAKE_SHARED_LINKER_FLAGS="$ANDROID_LDFLAGS" \
        -DCMAKE_FIND_ROOT_PATH="$TOOLCHAIN;$SYSROOT" \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY

    if [ $? -ne 0 ]; then
        print_error "x265 CMake 配置失败 for $ARCH"
        return 1
    fi

    cd "$BUILD_DIR" || return 1
    print_success "当前目录:$pwd,正在替换-lpthread为空"
    find . -name "link.txt" -exec sed -i '' 's/-lpthread//g' {} +

    pwd
    sleep 3

    make -j$(sysctl -n hw.ncpu)
    if [ $? -ne 0 ]; then
        print_error "x265 编译失败 for $ARCH"
        return 1
    fi

    make install
    if [ $? -ne 0 ]; then
        print_error "x265 安装失败 for $ARCH"
        return 1
    fi

    print_success "x265 for $ARCH 编译完成"
    return 0
}

main() {
    print_info "开始在 macOS ARM 平台编译 x264 和 x265 库"
    print_info "平台: $(uname -sm)"
    print_info "NDK: $NDK"
    print_info "API: $API"
    print_info "架构: ${ARCHS[*]}"

    check_environment
    START_TIME=$(date +%s)
    for ARCH in "${ARCHS[@]}"; do
        echo ""
        print_info "===================================================="
        print_info "开始处理架构: $ARCH"
        print_info "===================================================="

        print_info "--- 编译 x264 ($ARCH) ---"
        build_x264 "$ARCH"
        if [ $? -ne 0 ]; then
            print_error "x264 编译失败，跳过 x265"
            continue
        fi

        print_info "--- 编译 x265 ($ARCH) ---"
        build_x265 "$ARCH"
        if [ $? -ne 0 ]; then
            print_error "x265 编译失败"
        fi

        print_success "架构 $ARCH 处理完成"
    done

    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))

    echo ""
    print_info "===================================================="
    print_success "所有架构编译完成!"
    print_info "总耗时: $((ELAPSED_TIME / 60)) 分 $((ELAPSED_TIME % 60)) 秒"
    print_info "===================================================="

    print_info "输出目录:"
    print_info "x264: $X264_SOURCE_DIR/../android_x264_install/"
    print_info "x265: $X265_SOURCE_DIR/../../android_x265_install/"

    sleep 3
    file $HOME/Desktop/android_x26*/arm*/lib/*.so
    file $HOME/Desktop/android_x26*/x86_64/lib/*.so
}

if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -d "$HOME/Library/Android/sdk/ndk/25.1.8937393" ]; then
        export ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk/25.1.8937393"
        print_info "自动设置 ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
    elif [ -d "$HOME/Android/sdk/ndk/25.1.8937393" ]; then
        export ANDROID_NDK_HOME="$HOME/Android/sdk/ndk/25.1.8937393"
        print_info "自动设置 ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
    else
        print_error "请设置 ANDROID_NDK_HOME 环境变量"
        print_error "例如: export ANDROID_NDK_HOME=\$HOME/Library/Android/sdk/ndk/25.1.8937393"
        exit 1
    fi
fi

main
