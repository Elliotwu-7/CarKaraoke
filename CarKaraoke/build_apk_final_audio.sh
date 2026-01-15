#!/bin/bash

echo "正在构建带音频功能的CarKaraoke APK..."

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
    
    // 音频增益设置 - 8倍增益
    private static final float AUDIO_GAIN = 8.0f; // 8倍增益，平衡音量和音质
    
    // 额外的音量增强因子
    private static final float VOLUME_BOOST = 1.2f; // 额外20%音量提升，保持良好音质
    
    private AudioRecord audioRecord;
    private AudioTrack audioTrack;
    private boolean isRecording = false;
    private Thread recordingThread;
    private TextView statusView;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        Log.i(TAG, "应用启动，初始化音频功能");
        
        // 获取系统主题模式，判断是深色还是浅色
        int currentNightMode = getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkMode = currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        
        // 低饱和度配色方案
        int backgroundColor = isDarkMode ? Color.parseColor("#1e1e1e") : Color.parseColor("#f5f5f5"); // 深色/浅色背景
        int textColor = isDarkMode ? Color.parseColor("#e0e0e0") : Color.parseColor("#333333"); // 深色/浅色文字
        int statusColor = isDarkMode ? Color.parseColor("#90caf9") : Color.parseColor("#1976d2"); // 低饱和蓝色状态
        int startButtonColor = isDarkMode ? Color.parseColor("#81c784") : Color.parseColor("#4caf50"); // 低饱和绿色
        int stopButtonColor = isDarkMode ? Color.parseColor("#e57373") : Color.parseColor("#f44336"); // 低饱和红色
        int aboutButtonColor = isDarkMode ? Color.parseColor("#ffb74d") : Color.parseColor("#ff9800"); // 低饱和橙色
        
        // 创建线性布局
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setBackgroundColor(backgroundColor);
        layout.setPadding(80, 80, 80, 80);
        layout.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        
        // 添加布局参数，设置子视图间距
        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        layoutParams.setMargins(0, 0, 0, 30); // 子视图之间的外边距
        
        // 创建标题文本
        TextView titleView = new TextView(this);
        titleView.setText("车机版无麦K歌应用");
        titleView.setTextSize(42);
        titleView.setTextColor(textColor);
        titleView.setTypeface(null, Typeface.BOLD);
        titleView.setGravity(android.view.Gravity.CENTER);
        titleView.setPadding(0, 0, 0, 40);
        
        // 创建状态文本
        statusView = new TextView(this);
        statusView.setText("等待开始K歌");
        statusView.setTextSize(28);
        statusView.setTextColor(statusColor);
        statusView.setGravity(android.view.Gravity.CENTER);
        statusView.setPadding(0, 0, 0, 40);
        statusView.setTypeface(null, Typeface.ITALIC);
        
        // 创建开始按钮
        Button startButton = new Button(this);
        startButton.setText("开始K歌");
        startButton.setTextSize(24);
        startButton.setTextColor(isDarkMode ? Color.WHITE : Color.WHITE);
        startButton.setBackgroundColor(startButtonColor);
        startButton.setPadding(50, 25, 50, 25);
        startButton.setLayoutParams(layoutParams);
        startButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                startAudioTest();
                statusView.setText("K歌中...");
                statusView.setTextColor(startButtonColor);
            }
        });
        
        // 创建停止按钮
        Button stopButton = new Button(this);
        stopButton.setText("停止K歌");
        stopButton.setTextSize(24);
        stopButton.setTextColor(isDarkMode ? Color.WHITE : Color.WHITE);
        stopButton.setBackgroundColor(stopButtonColor);
        stopButton.setPadding(50, 25, 50, 25);
        stopButton.setLayoutParams(layoutParams);
        stopButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                stopAudioTest();
                statusView.setText("K歌已停止");
                statusView.setTextColor(stopButtonColor);
            }
        });
        
        // 创建关于按钮
        Button aboutButton = new Button(this);
        aboutButton.setText("关于");
        aboutButton.setTextSize(24);
        aboutButton.setTextColor(isDarkMode ? Color.WHITE : Color.WHITE);
        aboutButton.setBackgroundColor(aboutButtonColor);
        aboutButton.setPadding(50, 25, 50, 25);
        aboutButton.setLayoutParams(layoutParams);
        aboutButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                showAboutDialog();
            }
        });
        
        // 添加视图到布局
        layout.addView(titleView);
        layout.addView(statusView);
        layout.addView(startButton);
        layout.addView(stopButton);
        layout.addView(aboutButton);
        
        // 设置布局为内容视图
        setContentView(layout);
        
        Log.i(TAG, "UI初始化完成，准备开始音频测试");
    }
    
    private void startAudioTest() {
        Log.i(TAG, "开始K歌，初始化AudioRecord和AudioTrack");
        
        // 不主动请求音频焦点，改为使用音频属性标记，让系统智能处理
        // 这样可以确保其他音乐应用能够继续播放
        Log.i(TAG, "使用智能音频处理，允许其他音乐继续播放");
        
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
        
        // 初始化AudioTrack，使用MUSIC流，从主扬声器播放
        try {
            audioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC, // 使用音乐流，从主扬声器播放
                SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AUDIO_FORMAT,
                BUFFER_SIZE,
                AudioTrack.MODE_STREAM
            );
            Log.i(TAG, "AudioTrack初始化成功，使用音乐流从主扬声器播放");
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
                            
                            // 应用音频增益以增加音量
                            applyGain(buffer, readBytes);
                            
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
        Log.i(TAG, "停止K歌");
        
        isRecording = false;
        
        if (recordingThread != null) {
            try {
                recordingThread.join();
                Log.i(TAG, "K歌线程已停止");
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
    
    /**
     * 应用音频增益以增加音量
     * @param buffer 包含16位PCM样本的音频缓冲区
     * @param readBytes 读取的字节数
     */
    private void applyGain(byte[] buffer, int readBytes) {
        // 16位PCM，每个样本2字节
        for (int i = 0; i < readBytes; i += 2) {
            // 将2字节转换为short
            short sample = (short) ((buffer[i] & 0xFF) | (buffer[i + 1] << 8));
            
            // 转换为float应用增益
            float floatSample = sample;
            
            // 应用主增益和额外的音量增强
            floatSample *= AUDIO_GAIN;
            floatSample *= VOLUME_BOOST;
            
            // 限制在16位PCM范围内，防止削波
            floatSample = Math.max(-32768.0f, Math.min(32767.0f, floatSample));
            
            // 转换回short
            short amplifiedSample = (short) floatSample;
            
            // 将short转换回2字节写入缓冲区
            buffer[i] = (byte) (amplifiedSample & 0xFF);
            buffer[i + 1] = (byte) ((amplifiedSample >> 8) & 0xFF);
        }
        Log.d(TAG, "应用了 " + AUDIO_GAIN + " 倍增益和 " + VOLUME_BOOST + " 倍音量增强");
    }
    
    /**
     * 显示关于对话框
     */
    private void showAboutDialog() {
        // 获取系统主题模式，保持对话框与系统主题一致
        int currentNightMode = getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkMode = currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("关于车机无麦K歌");
        
        // 更新关于信息，按照要求修改
        String aboutMessage = "- 版本号：1.0.0 \n\n"
                            + "- 作者信息：由邪恶银渐层@小红书、先天BUG圣体@懂车帝制作 \n\n"
                            + "- 问题反馈：Elliotwu77@163.com";
        
        builder.setMessage(aboutMessage);
        builder.setPositiveButton("确定", new android.content.DialogInterface.OnClickListener() {
            public void onClick(android.content.DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        
        android.app.AlertDialog dialog = builder.create();
        dialog.show();
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

# 步骤4：生成dex文件（包含所有class文件）
# 找到所有class文件
CLASS_FILES="$(find "${PROJECT_DIR}/temp_build/com/example/carkaraoke/" -name "*.class")"
echo "=== 找到的class文件 ==="
echo "${CLASS_FILES}"

# 生成dex文件
if [ ! -z "${CLASS_FILES}" ]; then
    echo "正在生成dex文件..."
    "${BUILD_TOOLS}/d8" ${CLASS_FILES} --lib "${PLATFORM}/android.jar" --output "${PROJECT_DIR}/temp_build"
else
    echo "错误：没有找到class文件！"
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
    adb install -r "${PROJECT_DIR}/${APK_NAME}" 2>/dev/null || echo "自动安装到模拟器失败，请手动安装"
    echo ""
    echo "=== 使用说明 ==="
    echo "1. 打开应用后授予麦克风权限"
    echo "2. 点击\"开始K歌\"按钮，应用将以8倍增益处理麦克风音频"
    echo "3. 声音将从主扬声器播放，与音乐混合输出"
    echo "4. 可以通过调整车机的音量旋钮控制整体音量"
    echo ""
    echo "=== 测试完成 ==="
    echo "请手动在设备中操作应用进行音频测试"
    echo "使用 'adb logcat | grep -i CarKaraoke' 命令查看详细日志"
else
    echo "构建失败！"
fi
