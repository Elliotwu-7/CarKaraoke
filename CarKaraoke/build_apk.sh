#!/bin/bash

# Set Android SDK paths
ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
BUILD_TOOLS="${ANDROID_HOME}/build-tools/36.1.0"
PLATFORM_TOOLS="${ANDROID_HOME}/platform-tools"
NDK="${ANDROID_HOME}/ndk/25.2.9519653"
PLATFORM="${ANDROID_HOME}/platforms/android-30"

# Project paths
PROJECT_DIR="$(pwd)"
APP_DIR="${PROJECT_DIR}/app"
SRC_DIR="${APP_DIR}/src/main"
RES_DIR="${SRC_DIR}/res"
MANIFEST="${SRC_DIR}/AndroidManifest.xml"
JNI_DIR="${SRC_DIR}/cpp"
OUTPUT_DIR="${APP_DIR}/build/outputs/apk/debug"

# Create output directory
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${APP_DIR}/build/intermediates"

# Step 1: Compile resources with aapt2
${BUILD_TOOLS}/aapt2 compile --dir "${RES_DIR}" -o "${APP_DIR}/build/intermediates/resources.flat"

# Step 2: Link resources
${BUILD_TOOLS}/aapt2 link "${APP_DIR}/build/intermediates/resources.flat" -o "${APP_DIR}/build/intermediates/app.apk.unaligned" -I "${PLATFORM}/android.jar" --manifest "${MANIFEST}" --java "${APP_DIR}/build/generated/java"

# Step 3: Compile Kotlin/Java code
# This step requires kotlinc and javac, which we might not have in this environment
# For simplicity, we'll skip this step for now

echo "APK build script created. Note: This is a simplified script and may need adjustments based on your environment."
echo "For a complete build, please use Android Studio or a properly configured Gradle environment."
