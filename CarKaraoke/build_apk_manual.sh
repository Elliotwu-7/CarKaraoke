#!/bin/bash

# Set Android SDK paths
ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
BUILD_TOOLS="${ANDROID_HOME}/build-tools/36.1.0"
PLATFORM_TOOLS="${ANDROID_HOME}/platform-tools"
CMD_TOOLS="${ANDROID_HOME}/cmdline-tools/latest/bin"
PLATFORM="${ANDROID_HOME}/platforms/android-30"

# Project paths
PROJECT_DIR="$(pwd)"
APP_DIR="${PROJECT_DIR}/app"
SRC_DIR="${APP_DIR}/src/main"
RES_DIR="${SRC_DIR}/res"
MANIFEST="${SRC_DIR}/AndroidManifest.xml"
JAVA_DIR="${SRC_DIR}/java"
KOTLIN_DIR="${SRC_DIR}/kotlin"
LIB_DIR="${APP_DIR}/libs"
OUTPUT_DIR="${APP_DIR}/build/outputs/apk/debug"

# Create output and intermediate directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${APP_DIR}/build/intermediates/aapt2/compiled"
mkdir -p "${APP_DIR}/build/intermediates/aapt2/linked"
mkdir -p "${APP_DIR}/build/intermediates/javac"
mkdir -p "${APP_DIR}/build/intermediates/dex"
mkdir -p "${APP_DIR}/build/intermediates/unaligned"
mkdir -p "${APP_DIR}/build/intermediates/aligned"
mkdir -p "${APP_DIR}/build/generated/java"
mkdir -p "${APP_DIR}/build/generated/kotlin"

# Step 1: Compile resources with aapt2
echo "Compiling resources..."
${BUILD_TOOLS}/aapt2 compile --dir "${RES_DIR}" -o "${APP_DIR}/build/intermediates/aapt2/compiled/resources.flat"

# Step 2: Link resources to generate APK base
echo "Linking resources..."
${BUILD_TOOLS}/aapt2 link "${APP_DIR}/build/intermediates/aapt2/compiled/resources.flat" \
    -o "${APP_DIR}/build/intermediates/aapt2/linked/app.apk" \
    -I "${PLATFORM}/android.jar" \
    --manifest "${MANIFEST}" \
    --java "${APP_DIR}/build/generated/java"

# Step 3: Download required dependencies
# Note: This is a simplified approach. In a real build, you would resolve dependencies from Maven repositories
echo "Downloading dependencies..."
# We'll skip this step for now, assuming we have the required JAR files in the lib directory

# Step 4: Compile Java code
echo "Compiling Java code..."
if [ -d "${JAVA_DIR}" ]; then
    # Compile generated Java files first
    if [ -d "${APP_DIR}/build/generated/java" ]; then
        javac -d "${APP_DIR}/build/intermediates/javac" \
            -cp "${PLATFORM}/android.jar:${LIB_DIR}/*" \
            "${APP_DIR}/build/generated/java"/**/*.java
    fi
    # Compile main Java files
    javac -d "${APP_DIR}/build/intermediates/javac" \
        -cp "${PLATFORM}/android.jar:${LIB_DIR}/*:${APP_DIR}/build/intermediates/javac" \
        "${JAVA_DIR}/**/*.java"
fi

# Step 5: Compile Kotlin code
echo "Compiling Kotlin code..."
if [ -d "${KOTLIN_DIR}" ]; then
    # Note: This requires kotlinc to be in the PATH
    # For simplicity, we'll skip this step for now
    echo "Kotlin compilation skipped - kotlinc not available in PATH"
fi

# Step 6: Create classes.dex using d8
echo "Creating DEX file..."
${CMD_TOOLS}/d8 "${APP_DIR}/build/intermediates/javac/**/*.class" \
    --lib "${PLATFORM}/android.jar" \
    --output "${APP_DIR}/build/intermediates/dex"

# Step 7: Add classes.dex to APK using zip
echo "Adding DEX to APK..."
cp "${APP_DIR}/build/intermediates/aapt2/linked/app.apk" "${APP_DIR}/build/intermediates/unaligned/app-unaligned.apk"
zip -j "${APP_DIR}/build/intermediates/unaligned/app-unaligned.apk" "${APP_DIR}/build/intermediates/dex/classes.dex"

# Step 8: Align APK using zipalign
echo "Aligning APK..."
${BUILD_TOOLS}/zipalign 4 \
    "${APP_DIR}/build/intermediates/unaligned/app-unaligned.apk" \
    "${APP_DIR}/build/intermediates/aligned/app-aligned.apk"

# Step 9: Sign APK using apksigner
echo "Signing APK..."
# Create a debug keystore if it doesn't exist
if [ ! -f "${PROJECT_DIR}/debug.keystore" ]; then
    echo "Creating debug keystore..."
    keytool -genkey -v -keystore "${PROJECT_DIR}/debug.keystore" \
        -storepass android -keypass android \
        -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA -keysize 2048 -validity 10000
fi

# Sign the APK
${BUILD_TOOLS}/apksigner sign --ks "${PROJECT_DIR}/debug.keystore" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out "${OUTPUT_DIR}/app-debug.apk" \
    "${APP_DIR}/build/intermediates/aligned/app-aligned.apk"

echo "APK build completed!"
echo "Debug APK generated at: ${OUTPUT_DIR}/app-debug.apk"
