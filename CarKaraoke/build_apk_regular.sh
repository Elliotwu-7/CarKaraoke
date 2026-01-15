#!/bin/bash

echo "正在构建使用普通Activity的CarKaraoke APK..."

# 设置Android SDK路径
ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
BUILD_TOOLS="${ANDROID_HOME}/build-tools/36.1.0"
PLATFORM="${ANDROID_HOME}/platforms/android-30"

# 项目路径
PROJECT_DIR="$(pwd)"
APK_NAME="CarKaraoke.apk"

# 清理之前的构建产物
rm -f "${PROJECT_DIR}/${APK_NAME}"
rm -rf "${PROJECT_DIR}/temp_build"
mkdir -p "${PROJECT_DIR}/temp_build"

# 步骤1：创建AndroidManifest.xml，使用普通Activity
cat > "${PROJECT_DIR}/temp_build/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.carkaraoke"
    android:versionCode="1"
    android:versionName="1.0">
    
    <uses-sdk 
        android:minSdkVersion="29" 
        android:targetSdkVersion="30" />
    
    <application 
        android:label="CarKaraoke">
        <activity 
            android:name="com.example.carkaraoke.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 步骤2：创建简单的MainActivity类
mkdir -p "${PROJECT_DIR}/temp_build/com/example/carkaraoke"
cat > "${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.java" << 'EOF'
package com.example.carkaraoke;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView textView = new TextView(this);
        textView.setText("车机版无麦K歌应用");
        textView.setTextSize(24);
        setContentView(textView);
    }
}
EOF

# 步骤3：编译Java类
javac -d "${PROJECT_DIR}/temp_build" -cp "${PLATFORM}/android.jar" "${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.java"

# 步骤4：生成dex文件
"${BUILD_TOOLS}/d8" "${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.class" --lib "${PLATFORM}/android.jar" --output "${PROJECT_DIR}/temp_build"

# 步骤5：使用aapt创建APK
"${BUILD_TOOLS}/aapt" package -f -M "${PROJECT_DIR}/temp_build/AndroidManifest.xml" -I "${PLATFORM}/android.jar" -F "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build"

# 步骤6：添加classes.dex到APK
zip -j "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build/classes.dex"

# 步骤7：签名APK
if [ ! -f "${PROJECT_DIR}/debug.keystore" ]; then
    echo "正在生成调试密钥库..."
    keytool -genkey -v -keystore "${PROJECT_DIR}/debug.keystore" \
        -storepass android -keypass android \
        -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA -keysize 2048 -validity 10000
fi

echo "正在签名APK..."
"${BUILD_TOOLS}/apksigner" sign --ks "${PROJECT_DIR}/debug.keystore" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --min-sdk-version 29 \
    --out "${PROJECT_DIR}/${APK_NAME}" \
    "${PROJECT_DIR}/temp_build/app-unsigned.apk"

# 步骤8：清理临时文件
rm -rf "${PROJECT_DIR}/temp_build"

# 验证APK是否生成成功
if [ -f "${PROJECT_DIR}/${APK_NAME}" ]; then
    echo "构建成功！"
    echo "最终APK文件：${PROJECT_DIR}/${APK_NAME}"
    echo "文件大小：$(du -h "${PROJECT_DIR}/${APK_NAME}" | cut -f1)"
    echo "APK信息："
    "${BUILD_TOOLS}/aapt" dump badging "${PROJECT_DIR}/${APK_NAME}" 2>/dev/null | head -10
else
    echo "构建失败！"
fi
