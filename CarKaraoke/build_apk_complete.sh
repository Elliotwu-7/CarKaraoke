#!/bin/bash

echo "正在构建完整的CarKaraoke APK..."

# 设置Android SDK路径
ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
BUILD_TOOLS="${ANDROID_HOME}/build-tools/36.1.0"
PLATFORM="${ANDROID_HOME}/platforms/android-30"
PLATFORM_TOOLS="${ANDROID_HOME}/platform-tools"

# 项目路径
PROJECT_DIR="$(pwd)"
APK_NAME="CarKaraoke.apk"

# 清理之前的构建产物
rm -f "${PROJECT_DIR}/${APK_NAME}"
rm -rf "${PROJECT_DIR}/temp_build"
mkdir -p "${PROJECT_DIR}/temp_build"

# 步骤1：创建基本的AndroidManifest.xml
cat > "${PROJECT_DIR}/temp_build/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.carkaraoke"
    android:versionCode="1"
    android:versionName="1.0">
    
    <uses-sdk 
        android:minSdkVersion="29" 
        android:targetSdkVersion="30" />
    
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application 
        android:label="CarKaraoke" 
        android:icon="@mipmap/ic_launcher">
        <activity 
            android:name="android.app.NativeActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 步骤2：创建资源目录和空资源
mkdir -p "${PROJECT_DIR}/temp_build/res/values"
echo '<resources><string name="app_name">CarKaraoke</string></resources>' > "${PROJECT_DIR}/temp_build/res/values/strings.xml"

# 步骤3：使用aapt2编译资源
"${BUILD_TOOLS}/aapt2" compile --dir "${PROJECT_DIR}/temp_build/res" -o "${PROJECT_DIR}/temp_build/compiled_res.flat"
"${BUILD_TOOLS}/aapt2" link "${PROJECT_DIR}/temp_build/compiled_res.flat" -o "${PROJECT_DIR}/temp_build/resources.apk" -I "${PLATFORM}/android.jar" --manifest "${PROJECT_DIR}/temp_build/AndroidManifest.xml" --java "${PROJECT_DIR}/temp_build"

# 步骤4：创建一个简单的Java类
mkdir -p "${PROJECT_DIR}/temp_build/com/example/carkaraoke"
cat > "${PROJECT_DIR}/temp_build/HelloWorld.java" << 'EOF'
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, CarKaraoke!");
    }
}
EOF

# 步骤5：编译Java类
javac -d "${PROJECT_DIR}/temp_build" "${PROJECT_DIR}/temp_build/HelloWorld.java"

# 步骤6：生成dex文件
"${BUILD_TOOLS}/d8" "${PROJECT_DIR}/temp_build/HelloWorld.class" --lib "${PLATFORM}/android.jar" --output "${PROJECT_DIR}/temp_build"

# 步骤7：准备APK结构
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/arm64-v8a"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/armeabi-v7a"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/x86"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/x86_64"

# 步骤8：从resources.apk中提取文件
unzip -q "${PROJECT_DIR}/temp_build/resources.apk" -d "${PROJECT_DIR}/temp_build/apk"

# 步骤9：添加classes.dex
cp "${PROJECT_DIR}/temp_build/classes.dex" "${PROJECT_DIR}/temp_build/apk/"

# 步骤10：创建未签名的APK
cd "${PROJECT_DIR}/temp_build/apk"
zip -r "../app-unaligned.apk" *
cd "${PROJECT_DIR}"

# 步骤11：对齐APK
"${BUILD_TOOLS}/zipalign" 4 "${PROJECT_DIR}/temp_build/app-unaligned.apk" "${PROJECT_DIR}/temp_build/app-aligned.apk"

# 步骤12：签名APK
if [ ! -f "${PROJECT_DIR}/debug.keystore" ]; then
    keytool -genkey -v -keystore "${PROJECT_DIR}/debug.keystore" \
        -storepass android -keypass android \
        -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA -keysize 2048 -validity 10000
fi

"${BUILD_TOOLS}/apksigner" sign --ks "${PROJECT_DIR}/debug.keystore" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out "${PROJECT_DIR}/${APK_NAME}" \
    "${PROJECT_DIR}/temp_build/app-aligned.apk"

# 步骤13：清理临时文件
rm -rf "${PROJECT_DIR}/temp_build"

# 验证APK是否生成成功
if [ -f "${PROJECT_DIR}/${APK_NAME}" ]; then
    echo "构建成功！"
    echo "最终APK文件：${PROJECT_DIR}/${APK_NAME}"
    echo "文件大小：$(du -h "${PROJECT_DIR}/${APK_NAME}" | cut -f1)"
    echo "正在安装到模拟器..."
    "${PLATFORM_TOOLS}/adb" install -r "${PROJECT_DIR}/${APK_NAME}"
    if [ $? -eq 0 ]; then
        echo "APK安装成功！"
        echo "正在启动应用..."
        "${PLATFORM_TOOLS}/adb" shell am start -n com.example.carkaraoke/android.app.NativeActivity
    else
        echo "APK安装失败，请检查日志。"
    fi
else
    echo "构建失败！"
fi
