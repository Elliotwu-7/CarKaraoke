#!/bin/bash

echo "正在构建简单音频功能的CarKaraoke APK..."

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

# 步骤1：创建AndroidManifest.xml，添加音频权限
cat > "${PROJECT_DIR}/temp_build/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.carkaraoke"
    android:versionCode="1"
    android:versionName="1.0">
    
    <uses-sdk 
        android:minSdkVersion="29" 
        android:targetSdkVersion="30" />
    
    <!-- 添加音频相关权限 -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    
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

# 步骤2：创建简单的带音频功能的MainActivity类
mkdir -p "${PROJECT_DIR}/temp_build/com/example/carkaraoke"
cat > "${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.java" << 'EOF'
package com.example.carkaraoke;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Button;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.MediaRecorder;
import android.view.View;
import android.util.Log;

public class MainActivity extends Activity {
    private static final String TAG = "CarKaraoke";    
    
    // 音频参数
    private static final int SAMPLE_RATE = 44100;
    private static final int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * 2;
    
    private AudioRecord audioRecord;
    private AudioTrack audioTrack;
    private boolean isRecording = false;
    private Thread recordingThread;
    private TextView statusView;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        Log.i(TAG, "应用启动，初始化音频功能");
        
        // 创建线性布局
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setBackgroundColor(Color.BLACK);
        layout.setPadding(50, 50, 50, 50);
        
        // 创建标题文本
        TextView titleView = new TextView(this);
        titleView.setText("车机版无麦K歌应用");
        titleView.setTextSize(36);
        titleView.setTextColor(Color.WHITE);
        titleView.setTypeface(null, Typeface.BOLD);
        titleView.setPadding(0, 0, 0, 20);
        
        // 创建状态文本
        statusView = new TextView(this);
        statusView.setText("等待开始音频测试");
        statusView.setTextSize(24);
        statusView.setTextColor(Color.GRAY);
        statusView.setPadding(0, 0, 0, 20);
        
        // 创建开始按钮
        Button startButton = new Button(this);
        startButton.setText("开始音频测试");
        startButton.setTextSize(20);
        startButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                startAudioTest();
                statusView.setText("正在测试音频...");
                statusView.setTextColor(Color.GREEN);
            }
        });
        
        // 创建停止按钮
        Button stopButton = new Button(this);
        stopButton.setText("停止音频测试");
        stopButton.setTextSize(20);
        stopButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                stopAudioTest();
                statusView.setText("音频测试已停止");
                statusView.setTextColor(Color.RED);
            }
        });
        
        // 添加视图到布局
        layout.addView(titleView);
        layout.addView(statusView);
        layout.addView(startButton);
        layout.addView(stopButton);
        
        // 设置布局为内容视图
        setContentView(layout);
        
        Log.i(TAG, "UI初始化完成，准备开始音频测试");
    }
    
    private void startAudioTest() {
        Log.i(TAG, "开始音频测试，初始化AudioRecord和AudioTrack");
        
        // 初始化AudioRecord
        try {
            audioRecord = new AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                BUFFER_SIZE
            );
            Log.i(TAG, "AudioRecord初始化成功");
        } catch (Exception e) {
            Log.e(TAG, "AudioRecord初始化失败: " + e.getMessage());
            return;
        }
        
        // 初始化AudioTrack
        try {
            audioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AUDIO_FORMAT,
                BUFFER_SIZE,
                AudioTrack.MODE_STREAM
            );
            Log.i(TAG, "AudioTrack初始化成功");
        } catch (Exception e) {
            Log.e(TAG, "AudioTrack初始化失败: " + e.getMessage());
            audioRecord.release();
            return;
        }
        
        // 开始录制和播放
        isRecording = true;
        audioRecord.startRecording();
        audioTrack.play();
        
        Log.i(TAG, "开始录制和播放音频");
        
        // 创建录音线程
        recordingThread = new Thread(new Runnable() {
            public void run() {
                byte[] buffer = new byte[BUFFER_SIZE];
                
                while (isRecording) {
                    try {
                        // 从麦克风读取音频数据
                        int readBytes = audioRecord.read(buffer, 0, buffer.length);
                        if (readBytes > 0) {
                            Log.d(TAG, "读取到音频数据: " + readBytes + " 字节");
                            
                            // 播放音频数据
                            int writeBytes = audioTrack.write(buffer, 0, readBytes);
                            Log.d(TAG, "播放音频数据: " + writeBytes + " 字节");
                        }
                    } catch (Exception e) {
                        Log.e(TAG, "音频处理失败: " + e.getMessage());
                        break;
                    }
                }
            }
        });
        
        recordingThread.start();
        Log.i(TAG, "音频测试线程启动");
    }
    
    private void stopAudioTest() {
        Log.i(TAG, "停止音频测试");
        
        isRecording = false;
        
        if (recordingThread != null) {
            try {
                recordingThread.join();
                Log.i(TAG, "音频测试线程已停止");
            } catch (InterruptedException e) {
                Log.e(TAG, "线程停止失败: " + e.getMessage());
            }
        }
        
        if (audioRecord != null) {
            audioRecord.stop();
            audioRecord.release();
            audioRecord = null;
            Log.i(TAG, "AudioRecord已释放");
        }
        
        if (audioTrack != null) {
            audioTrack.stop();
            audioTrack.release();
            audioTrack = null;
            Log.i(TAG, "AudioTrack已释放");
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopAudioTest();
        Log.i(TAG, "应用销毁，音频资源已释放");
    }
}
EOF

# 步骤3：编译Java类
javac -d "${PROJECT_DIR}/temp_build" -cp "${PLATFORM}/android.jar" "${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.java"

# 列出编译生成的class文件
echo "=== 编译生成的class文件 ==="
ls -la "${PROJECT_DIR}/temp_build/com/example/carkaraoke/"

# 步骤4：生成dex文件（直接指定MainActivity类文件，不使用通配符）
MAIN_ACTIVITY_CLASS="${PROJECT_DIR}/temp_build/com/example/carkaraoke/MainActivity.class"
if [ -f "${MAIN_ACTIVITY_CLASS}" ]; then
    echo "正在生成dex文件..."
    "${BUILD_TOOLS}/d8" "${MAIN_ACTIVITY_CLASS}" --lib "${PLATFORM}/android.jar" --output "${PROJECT_DIR}/temp_build"
else
    echo "错误：MainActivity.class文件不存在！"
    exit 1
fi

# 步骤5：检查dex文件是否生成成功
if [ -f "${PROJECT_DIR}/temp_build/classes.dex" ]; then
    echo "classes.dex文件生成成功！"
else
    echo "错误：classes.dex文件生成失败！"
    exit 1
fi

# 步骤6：创建资源目录和空资源文件
mkdir -p "${PROJECT_DIR}/temp_build/res/values"
echo '<resources><string name="app_name">CarKaraoke</string></resources>' > "${PROJECT_DIR}/temp_build/res/values/strings.xml"

# 步骤7：使用aapt创建APK
"${BUILD_TOOLS}/aapt" package -f -v -M "${PROJECT_DIR}/temp_build/AndroidManifest.xml" -I "${PLATFORM}/android.jar" -F "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build/res"

# 步骤8：添加classes.dex到APK
zip -j "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build/classes.dex"

# 步骤9：签名APK
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

# 步骤10：清理临时文件
rm -rf "${PROJECT_DIR}/temp_build"

# 步骤11：验证APK是否生成成功
if [ -f "${PROJECT_DIR}/${APK_NAME}" ]; then
    echo "构建成功！"
    echo "最终APK文件：${PROJECT_DIR}/${APK_NAME}"
    echo "文件大小：$(du -h "${PROJECT_DIR}/${APK_NAME}" | cut -f1)"
    echo "正在安装到模拟器..."
    adb install -r "${PROJECT_DIR}/${APK_NAME}"
    if [ $? -eq 0 ]; then
        echo "APK安装成功！"
        echo "正在启动应用..."
        adb shell am start -n com.example.carkaraoke/.MainActivity
        echo ""
        echo "=== 音频测试说明 ==="
        echo "1. 应用启动后，点击\"开始音频测试\"按钮"
        echo "2. 应用将开始录制麦克风音频并实时播放"
        echo "3. 通过以下命令查看音频相关日志："
        echo "   adb logcat -d | grep -i CarKaraoke"
        echo "4. 点击\"停止音频测试\"按钮结束测试"
        echo ""
        echo "=== 正在显示实时日志 ==="
        echo "按Ctrl+C停止查看日志"
        echo "------------------------"
        # 显示实时日志
        adb logcat | grep -i CarKaraoke &
        LOG_PID=$!
        # 等待5秒后停止日志查看
        sleep 5
        kill $LOG_PID
    else
        echo "APK安装失败，请检查日志。"
    fi
else
    echo "构建失败！"
fi
