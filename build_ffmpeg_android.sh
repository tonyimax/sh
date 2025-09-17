#!/bin/bash
 
export NDK=$HOME/Library/Android/sdk/ndk/25.1.8937393
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
export API=28
export FFMPEG_DIR=$HOME/Desktop/FFmpeg
export FFMPEG_BUILD_DIR=$FFMPEG_DIR/../ffmpeg_android_build
rm -rf $HOME/Desktop/ffmpeg_android_build

export PATH=$TOOLCHAIN/bin:$PATH
export SYSROOT=$TOOLCHAIN/sysroot
export CC=clang
export CXX=clang++

ABIS=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")
 
mkdir -p "$FFMPEG_BUILD_DIR"
 
for ABI in "${ABIS[@]}"; do
    echo "=============================================="
    echo "正在编译 FFmpeg for ABI: $ABI"
    echo "=============================================="
 
    mkdir -p "$FFMPEG_BUILD_DIR/$ABI"
 
    case $ABI in
      armeabi-v7a)
        ARCH=arm
        CPU=armv7-a
        TARGET="armv7a-linux-androideabi$API"
        CC=$TOOLCHAIN/bin/clang
        CXX=$TOOLCHAIN/bin/clang++
        STRIP=$TOOLCHAIN/bin/llvm-strip
        EXTRA_CFLAGS="-target $TARGET -march=armv7-a -mfpu=neon -mfloat-abi=softfp"
        EXTRA_LDFLAGS="-target $TARGET -march=armv7-a -mfpu=neon -mfloat-abi=softfp -Wl,--fix-cortex-a8"
        ;;
      arm64-v8a)
        ARCH=aarch64
        CPU=armv8-a
        TARGET="aarch64-linux-android$API"
        CC=$TOOLCHAIN/bin/clang
        CXX=$TOOLCHAIN/bin/clang++
        STRIP=$TOOLCHAIN/bin/llvm-strip
        EXTRA_CFLAGS="-target $TARGET"
        EXTRA_LDFLAGS="-target $TARGET"
        ;;
      x86_64)
        ARCH=x86_64
        CPU=x86-64
        TARGET="x86_64-linux-android$API"
        CC=$TOOLCHAIN/bin/x86_64-linux-android$API-clang
        CXX=$TOOLCHAIN/bin/x86_64-linux-android$API-clang++
        STRIP=$TOOLCHAIN/bin/llvm-strip
        EXTRA_CFLAGS="-target $TARGET -m64"
        EXTRA_LDFLAGS="-target $TARGET -m64"
        ;;
      x86)
        ARCH=x86
        CPU=i686
        TARGET="i686-linux-android$API"
        CC=$TOOLCHAIN/bin/i686-linux-android$API-clang
        CXX=$TOOLCHAIN/bin/i686-linux-android$API-clang++
        STRIP=$TOOLCHAIN/bin/llvm-strip
        EXTRA_CFLAGS="-target $TARGET -m32"
        EXTRA_LDFLAGS="-target $TARGET -m32"
        ;;
    esac
 
    export CC="$CC $EXTRA_CFLAGS"
    export CXX="$CXX $EXTRA_CFLAGS"
    export AR="$TOOLCHAIN/bin/llvm-ar"
    export LD="$TOOLCHAIN/bin/ld"
    export STRIP="$TOOLCHAIN/bin/llvm-strip"
    export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
 
    cd "$FFMPEG_DIR" || return 1
 
    ./configure \
      --prefix="$FFMPEG_BUILD_DIR/$ABI" \
      --enable-cross-compile \
      --cross-prefix=$TOOLCHAIN/bin/llvm- \
      --sysroot=$TOOLCHAIN/sysroot \
      --target-os=android \
      --arch="$ARCH" \
      --cpu="$CPU" \
      --cc="$CC" \
      --cxx="$CXX" \
      --strip="$STRIP" \
      --extra-cflags="$EXTRA_CFLAGS -Os -fPIC" \
      --extra-ldflags="$EXTRA_LDFLAGS" \
      --enable-shared \
      --disable-static \
      --disable-programs \
      --disable-doc \
      --disable-avdevice \
      --disable-swresample \
      --disable-avfilter \
      --disable-symver \
      --disable-asm \
      --enable-decoder=h264 \
      --enable-decoder=hevc \
      --enable-parser=h264 \
      --enable-parser=hevc \
      --enable-demuxer=h264 \
      --enable-demuxer=hevc \
      --enable-encoder=libx264 \
      --enable-encoder=libx265 \
      --enable-gpl \
      --extra-cflags="-I$HOME/Desktop/android_x264_install/$ABI/include -I$HOME/Desktop/android_x264_install/$ABI/include" \
      --extra-ldflags="-L$HOME/Desktop/android_x264_install/$ABI/lib -L$HOME/Desktop/android_x265_install/$ABI/lib" \
      --enable-decoder=aac \
      --enable-decoder=mp3 \
      --enable-decoder=vp8 \
      --enable-decoder=vp9 \
      --enable-decoder=av1 \
      --enable-parser=aac \
      --enable-parser=mpeg4video
 
    if [ $? -eq 0 ]; then
        echo "配置 for $ABI 成功, 开始编译..."
        make clean
        make -j$(sysctl -n hw.logicalcpu)
        if [ $? -eq 0 ]; then
            make install
            echo "✅ FFmpeg for $ABI 架构编译成功!"
            echo "📁 库成功安装到: $FFMPEG_BUILD_DIR/$ABI"
 
            echo "🔍 正在验证H.264和H.265支持..."
            ffmpeg -codecs | grep -E "h264|hevc" || echo "Note: Use built ffmpeg binary to check codecs"
        else
            echo "❌ 验证失败 for $ABI"
            exit 1
        fi
    else
        echo "❌ 配置失败 for $ABI, please check the error messages above."
        exit 1
    fi
    
    echo ""
done
 
echo "=============================================="
echo "🎉 All ABIs built successfully!"
echo "📦 Output root directory: $OUTPUT_ROOT"
echo "📦 Individual ABI directories:"
for ABI in "${ABIS[@]}"; do
    echo "   - $OUTPUT_ROOT/$ABI/"
done
echo "=============================================="
 
echo "Creating unified include directory..."
UNIFIED_INCLUDE_DIR=$FFMPEG_BUILD_DIR/include
mkdir -p $UNIFIED_INCLUDE_DIR
 
cp -r $FFMPEG_BUILD_DIR/${ABIS[0]}/include/* $UNIFIED_INCLUDE_DIR/
echo "📁 Unified include directory: $UNIFIED_INCLUDE_DIR"
file $HOME/Desktop/ffmpeg_android_build/arm*/lib/*.so

echo "=============================================="
echo "🏗️  编译完成! 目录结构如下:"
echo "ffmpeg_android_build/"
echo "├── include/           # 通用头文件"
echo "├── arm64-v8a/         # arm64-v8a 库文件"
echo "│   ├── lib/"
echo "│   └── share/"
echo "└── armeabi-v7a/       # armeabi-v7a 库文件"
echo "    ├── lib/"
echo "    └── share/"
echo ""
echo "✅ Enabled codecs:"
echo "   - H.264 (AVC) Decoder"
echo "   - H.265 (HEVC) Decoder"
echo "   - H.264 Encoder (libx264, if external lib available)"
echo "   - H.265 Encoder (libx265, if external lib available)"
echo "   - AAC, MP3, VP8, VP9, AV1 Decoders"
echo "=============================================="
