#!/bin/bash

echo "正在构建CarKaraoke APK..."

# 设置Android SDK路径
export ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.1.0"

# 确保项目目录正确
cd /Users/elliotwu/Downloads/LK/CarKaraoke

# 检查是否存在gradlew脚本，如果不存在则下载
if [ ! -f "gradlew" ]; then
    echo "正在下载Gradle Wrapper..."
    # 使用curl下载gradle wrapper jar文件
    mkdir -p gradle/wrapper
    curl -o gradle/wrapper/gradle-wrapper.jar https://services.gradle.org/distributions/gradle-7.0.2-bin.zip
    # 创建gradlew脚本
    cat > gradlew << 'EOF'
#!/bin/bash

export GRADLE_HOME="$(dirname "$0")/gradle"
export PATH="$PATH:$GRADLE_HOME/bin"
gradle "$@"
EOF
    chmod +x gradlew
fi

# 创建settings.gradle文件（如果不存在）
if [ ! -f "settings.gradle" ]; then
    cat > settings.gradle << 'EOF'
include ':app'
rootProject.name = "CarKaraoke"
EOF
fi

# 创建build.gradle文件（如果不存在）
if [ ! -f "build.gradle" ]; then
    cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.4'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.5.31'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF
fi

# 创建app/build.gradle文件
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
    id 'kotlin-android'
}

android {
    compileSdkVersion 30
    buildToolsVersion "30.0.3"

    defaultConfig {
        applicationId "com.example.carkaraoke"
        minSdkVersion 29
        targetSdkVersion 30
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.7.0'
    implementation 'androidx.appcompat:appcompat:1.5.1'
    implementation 'com.google.android.material:material:1.7.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.legacy:legacy-support-v4:1.0.0'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.3'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'
}
EOF

# 创建app/src/main/AndroidManifest.xml文件
mkdir -p app/src/main
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.carkaraoke">

    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="CarKaraoke"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="landscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service
            android:name=".AudioProcessingService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback"/>
    </application>
</manifest>
EOF

# 创建app/src/main/java/com/example/carkaraoke/MainActivity.java
mkdir -p app/src/main/java/com/example/carkaraoke
cat > app/src/main/java/com/example/carkaraoke/MainActivity.java << 'EOF'
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

# 创建app/src/main/java/com/example/carkaraoke/AudioProcessingService.java
cat > app/src/main/java/com/example/carkaraoke/AudioProcessingService.java << 'EOF'
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

# 创建app/proguard-rules.pro文件
cat > app/proguard-rules.pro << 'EOF'
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
EOF

# 构建APK
echo "开始构建APK..."
./gradlew assembleDebug --no-daemon

# 检查构建结果
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "构建成功！"
    echo "APK文件路径：app/build/outputs/apk/debug/app-debug.apk"
    echo "正在复制到根目录..."
    cp app/build/outputs/apk/debug/app-debug.apk CarKaraoke.apk
    echo "最终APK文件：CarKaraoke.apk"
    echo "文件大小：$(du -h CarKaraoke.apk | cut -f1)"
else
    echo "构建失败！"
    echo "请检查构建日志以获取详细信息。"
fi
