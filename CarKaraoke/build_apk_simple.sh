#!/bin/bash

echo "正在构建CarKaraoke APK..."

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

# 步骤1：创建AndroidManifest.xml
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
            android:name="com.example.carkaraoke.MainActivity" 
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service 
            android:name="com.example.carkaraoke.AudioProcessingService" 
            android:exported="false" 
            android:foregroundServiceType="mediaPlayback" />
    </application>
</manifest>
EOF

# 步骤2：创建简单的Java类
cat > "${PROJECT_DIR}/temp_build/MainActivity.java" << 'EOF'
package com.example.carkaraoke;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {
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

cat > "${PROJECT_DIR}/temp_build/AudioProcessingService.java" << 'EOF'
package com.example.carkaraoke;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class AudioProcessingService extends Service {
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
EOF

# 步骤3：编译Java类
javac -d "${PROJECT_DIR}/temp_build" -cp "${PLATFORM}/android.jar" "${PROJECT_DIR}/temp_build/MainActivity.java" "${PROJECT_DIR}/temp_build/AudioProcessingService.java"

# 步骤4：生成dex文件
"${BUILD_TOOLS}/d8" --lib "${PLATFORM}/android.jar" "${PROJECT_DIR}/temp_build/com/example/carkaraoke/*.class" --output "${PROJECT_DIR}/temp_build"

# 步骤5：创建APK结构
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/arm64-v8a"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/armeabi-v7a"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/x86"
mkdir -p "${PROJECT_DIR}/temp_build/apk/lib/x86_64"
mkdir -p "${PROJECT_DIR}/temp_build/apk/res"
mkdir -p "${PROJECT_DIR}/temp_build/apk/assets"

# 复制文件到APK结构
cp "${PROJECT_DIR}/temp_build/classes.dex" "${PROJECT_DIR}/temp_build/apk/"

# 步骤6：使用aapt2编译资源（只创建空资源，因为我们没有实际的资源文件）
mkdir -p "${PROJECT_DIR}/temp_build/res/values"
echo '<resources></resources>' > "${PROJECT_DIR}/temp_build/res/values/strings.xml"
"${BUILD_TOOLS}/aapt2" compile --dir "${PROJECT_DIR}/temp_build/res" -o "${PROJECT_DIR}/temp_build/compiled_res.flat"
"${BUILD_TOOLS}/aapt2" link "${PROJECT_DIR}/temp_build/compiled_res.flat" -o "${PROJECT_DIR}/temp_build/resources.apk" -I "${PLATFORM}/android.jar" --manifest "${PROJECT_DIR}/temp_build/AndroidManifest.xml"

# 解压资源APK到我们的APK目录
unzip -q "${PROJECT_DIR}/temp_build/resources.apk" -d "${PROJECT_DIR}/temp_build/apk/"
rm "${PROJECT_DIR}/temp_build/resources.apk"

# 步骤7：创建未签名的APK
cd "${PROJECT_DIR}/temp_build/apk"
zip -r "../app-unaligned.apk" *
cd "${PROJECT_DIR}"

# 步骤8：对齐APK
"${BUILD_TOOLS}/zipalign" 4 "${PROJECT_DIR}/temp_build/app-unaligned.apk" "${PROJECT_DIR}/temp_build/app-aligned.apk"

# 步骤9：签名APK
if [ ! -f "${PROJECT_DIR}/debug.keystore" ]; then
    keytool -genkey -v -keystore "${PROJECT_DIR}/debug.keystore" \
        -storepass android -keypass android \
        -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA -keysize 2048 -validity 10000
fi

# 使用--min-sdk-version参数覆盖，解决无法确定最小SDK版本的问题
"${BUILD_TOOLS}/apksigner" sign --ks "${PROJECT_DIR}/debug.keystore" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --min-sdk-version 29 \
    --out "${PROJECT_DIR}/${APK_NAME}" \
    "${PROJECT_DIR}/temp_build/app-aligned.apk"

# 步骤10：清理临时文件
rm -rf "${PROJECT_DIR}/temp_build"

# 验证APK是否生成成功
if [ -f "${PROJECT_DIR}/${APK_NAME}" ]; then
    echo "构建成功！"
    echo "最终APK文件：${PROJECT_DIR}/${APK_NAME}"
    echo "文件大小：$(du -h "${PROJECT_DIR}/${APK_NAME}" | cut -f1)"
else
    echo "构建失败！"
fi
