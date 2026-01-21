#!/bin/bash

echo "正在构建带音频功能的CarKaraoke APK..."

# 设置Android SDK路径
ANDROID_HOME="/Users/elliotwu/Library/Android/sdk"
BUILD_TOOLS="${ANDROID_HOME}/build-tools/36.1.0"
PLATFORM="${ANDROID_HOME}/platforms/android-30"

# 项目路径 - 使用脚本所在目录
PROJECT_DIR="$(dirname "$(readlink -f "$0")")"
APK_NAME="CarKaraoke.apk"

# 清理之前的构建产物
rm -f "${PROJECT_DIR}/${APK_NAME}"
rm -rf "${PROJECT_DIR}/temp_build"
mkdir -p "${PROJECT_DIR}/temp_build"

# 步骤1：创建AndroidManifest.xml，添加音频权限和悬浮窗权限
cat > "${PROJECT_DIR}/temp_build/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.car.karake"
    android:versionCode="8"
    android:versionName="1.0.8">
    
    <uses-sdk 
        android:minSdkVersion="28" 
        android:targetSdkVersion="30" />
    
    <!-- 添加音频相关权限 -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <!-- 添加网络权限用于自动更新 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <!-- 添加文件访问权限 -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <!-- 添加安装应用权限 -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    
    <application 
        android:label="无麦K歌"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:networkSecurityConfig="@xml/network_security_config">
        <activity 
            android:name="com.car.karake.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service
            android:name="com.car.karake.FloatingWindowService"
            android:exported="false" />
    </application>
</manifest>
EOF

# 创建网络安全配置文件，确保Android 9兼容
mkdir -p "${PROJECT_DIR}/temp_build/res/xml"
cat > "${PROJECT_DIR}/temp_build/res/xml/network_security_config.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
EOF

# 步骤1.5：复制图标资源
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-anydpi-v26"
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-hdpi"
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-mdpi"
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-xhdpi"
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-xxhdpi"
mkdir -p "${PROJECT_DIR}/temp_build/res/mipmap-xxxhdpi"
mkdir -p "${PROJECT_DIR}/temp_build/res/drawable"

# 只复制必要的图标资源，避免主题冲突
cp -f "${PROJECT_DIR}/icon/res/mipmap-anydpi-v26/ic_launcher.xml" "${PROJECT_DIR}/temp_build/res/mipmap-anydpi-v26/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-anydpi-v26/ic_launcher_round.xml" "${PROJECT_DIR}/temp_build/res/mipmap-anydpi-v26/"

# 复制各种密度的图标文件
cp -f "${PROJECT_DIR}/icon/res/mipmap-hdpi/ic_launcher.png" "${PROJECT_DIR}/temp_build/res/mipmap-hdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-hdpi/ic_launcher_round.png" "${PROJECT_DIR}/temp_build/res/mipmap-hdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-hdpi/ic_launcher_foreground.png" "${PROJECT_DIR}/temp_build/res/mipmap-hdpi/"

cp -f "${PROJECT_DIR}/icon/res/mipmap-mdpi/ic_launcher.png" "${PROJECT_DIR}/temp_build/res/mipmap-mdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-mdpi/ic_launcher_round.png" "${PROJECT_DIR}/temp_build/res/mipmap-mdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-mdpi/ic_launcher_foreground.png" "${PROJECT_DIR}/temp_build/res/mipmap-mdpi/"

cp -f "${PROJECT_DIR}/icon/res/mipmap-xhdpi/ic_launcher.png" "${PROJECT_DIR}/temp_build/res/mipmap-xhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xhdpi/ic_launcher_round.png" "${PROJECT_DIR}/temp_build/res/mipmap-xhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xhdpi/ic_launcher_foreground.png" "${PROJECT_DIR}/temp_build/res/mipmap-xhdpi/"

cp -f "${PROJECT_DIR}/icon/res/mipmap-xxhdpi/ic_launcher.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xxhdpi/ic_launcher_round.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xxhdpi/ic_launcher_foreground.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxhdpi/"

cp -f "${PROJECT_DIR}/icon/res/mipmap-xxxhdpi/ic_launcher.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxxhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xxxhdpi/ic_launcher_round.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxxhdpi/"
cp -f "${PROJECT_DIR}/icon/res/mipmap-xxxhdpi/ic_launcher_foreground.png" "${PROJECT_DIR}/temp_build/res/mipmap-xxxhdpi/"

# 复制背景和前景文件
cp -f "${PROJECT_DIR}/icon/res/drawable/ic_launcher_background.xml" "${PROJECT_DIR}/temp_build/res/drawable/"
cp -f "${PROJECT_DIR}/icon/res/drawable/ic_launcher_foreground.xml" "${PROJECT_DIR}/temp_build/res/drawable/"

# 步骤2：创建简单的带音频功能的MainActivity类
mkdir -p "${PROJECT_DIR}/temp_build/com/car/karake"
cat > "${PROJECT_DIR}/temp_build/com/car/karake/MainActivity.java" << 'EOF'
package com.car.karake;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Button;
import android.widget.Toast;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.MediaRecorder;
import android.view.View;
import android.util.Log;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import android.os.Build;
import android.widget.Toast;
import android.Manifest;
import android.os.AsyncTask;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import android.os.Environment;
import java.net.URLConnection;
import android.app.PendingIntent;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends Activity {
    private static final String TAG = "CarKaraoke";    
    
    // 权限请求码
    private static final int REQUEST_RECORD_AUDIO_PERMISSION = 200;
    private static final int REQUEST_OVERLAY_PERMISSION = 300;
    private static final int REQUEST_STORAGE_PERMISSION = 400;
    
    // 安装状态标记
    private boolean isInstalling = false;
    
    /**
     * 添加日志条目到日志缓冲区
     * @param tag 日志标签
     * @param message 日志消息
     */
    private void addLog(String tag, String message) {
        // 获取当前时间
        String timestamp = new SimpleDateFormat("HH:mm:ss.SSS", Locale.getDefault()).format(new Date());
        
        // 构建日志条目
        String logEntry = timestamp + " [" + tag + "] " + message + "\n";
        
        // 添加到日志缓冲区
        logs.append(logEntry);
        
        // 检查日志行数，超过限制则移除最旧的日志
        String[] logLines = logs.toString().split("\n");
        if (logLines.length > MAX_LOG_LINES) {
            StringBuilder newLogs = new StringBuilder();
            for (int i = logLines.length - MAX_LOG_LINES; i < logLines.length; i++) {
                newLogs.append(logLines[i]).append("\n");
            }
            logs = newLogs;
        }
    }
    
    // 自动更新相关常量
    private static final String GITEE_REPO_URL = "https://gitee.com/elliot-wu/CarKaraoke";
    private static final String VERSION_CHECK_URL = "https://gitee.com/api/v5/repos/elliot-wu/CarKaraoke/releases/latest";
    private String APK_DOWNLOAD_URL = "";
    
    // 音频参数 - 平衡音质和延迟
    private static final int SAMPLE_RATE = 44100; // 提高采样率到44100Hz，显著改善音质
    private int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO; // 声道配置，单声道输入减少处理
    private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    private static final int BUFFER_SIZE = 512; // 优化缓冲区大小，进一步降低延迟（约11.6ms延迟）同时保持系统稳定性
    
    // 低通滤波器参数，用于减少高频嘶嘶声
    private static final float LOWPASS_CUTOFF = 3000.0f; // 截止频率3kHz
    private float[] lowpassHistory = new float[2]; // 滤波器历史状态
    
    // 声道配置选项
    private int[] channelConfigs = {AudioFormat.CHANNEL_IN_MONO, AudioFormat.CHANNEL_IN_STEREO};
    private String[] channelNames = {"单声道", "立体声"};
    private int currentChannelIndex = 0;
    
    // 输出声道配置选项 - 仅保留单声道
    private int outputChannelConfig = AudioFormat.CHANNEL_OUT_MONO;
    
    // 用于保存配置的SharedPreferences
    private android.content.SharedPreferences sharedPreferences;
    
    // 配置选项
    private boolean autoStartKaraoke = true; // 自动开始K歌
    private boolean updateNoRemind = false; // 更新不再提示
    
    // 音频增益设置 - 8倍增益
    private static final float AUDIO_GAIN = 8.0f; // 8倍增益，平衡音量和音质
    
    // 额外的音量增强因子
    private static final float VOLUME_BOOST = 1.2f; // 额外20%音量提升，保持良好音质
    
    private AudioRecord audioRecord;
    private AudioTrack audioTrack;
    private boolean isRecording = false;
    private Thread recordingThread;
    private TextView statusView;
    private LinearLayout statusCard;
    private TextView currentStatusView;
    private View statusIndicator;
    private Button mainToggleButton;
    private View toggleKnob;
    private android.widget.LinearLayout toggleContainer;
    private TextView gainValueView;
    private TextView echoValueView;
    private TextView delayValueView;
    private TextView dateView;
    
    // 音频效果控制参数
    private int delayTime = 0; // 延迟时间，单位ms，设为0完全消除延迟
    private float echoLevel = 0.0f; // 回声强度，设为0完全消除回声效果，减少延迟
    private float gainLevel = 1.8f; // 总增益，默认1.8倍（30%增幅），平衡音量和噪声
    
    // 主题模式变量
    private boolean isDarkMode;
    
    // 日志收集变量
    private StringBuilder logs = new StringBuilder();
    private static final int MAX_LOG_LINES = 500; // 最大日志行数
    
    // 广播接收器，用于接收悬浮窗发送的停止K歌命令
    private android.content.BroadcastReceiver stopKaraokeReceiver = new android.content.BroadcastReceiver() {
        @Override
        public void onReceive(android.content.Context context, android.content.Intent intent) {
            Log.i(TAG, "收到停止K歌广播");
            // 检查是否已经停止，避免重复调用
            if (isRecording) {
                stopAudioTest();
            }
        }
    };
    
    // 控制条控件
    private android.widget.SeekBar delaySeekBar;
    private android.widget.SeekBar echoSeekBar;
    private android.widget.SeekBar gainSeekBar;
    private TextView delayLabel;
    private TextView echoLabel;
    private TextView gainLabel;
    
    // 延迟缓冲区
    private float[] delayBuffer;
    private int delayBufferSize;
    private int delayBufferIndex = 0;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 设置全局异常处理器
        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
            @Override
            public void uncaughtException(Thread thread, Throwable throwable) {
                String errorLog = "应用崩溃 - " + throwable.getMessage() + "\n";
                for (StackTraceElement element : throwable.getStackTrace()) {
                    errorLog += "\tat " + element.toString() + "\n";
                }
                addLog("CRASH", errorLog);
                Log.e(TAG, errorLog);
                // 调用系统默认的异常处理器
                Thread.getDefaultUncaughtExceptionHandler().uncaughtException(thread, throwable);
            }
        });
        
        // 隐藏标题栏
        if (getActionBar() != null) {
            getActionBar().hide();
        }
        
        // 添加应用启动日志
        addLog(TAG, "应用启动，初始化音频功能");
        Log.i(TAG, "应用启动，初始化音频功能");
        
        // 检查是否是安装完成的回调
        Intent intent = getIntent();
        if (intent != null && "INSTALL_COMPLETE".equals(intent.getAction())) {
            Log.i(TAG, "收到安装完成回调，跳过更新检查");
            // 延迟一段时间后检查安装状态
            new android.os.Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    checkInstallationStatus();
                }
            }, 2000);
        }
        
        // 初始化SharedPreferences，用于保存配置
        sharedPreferences = getSharedPreferences("CarKaraokeConfig", MODE_PRIVATE);
        
        // 加载保存的配置
        loadConfig();
        
        // 强制设置默认增益值为1.8f（30%增幅），以覆盖任何旧的保存值
        gainLevel = 1.8f;
        
        // 检查和请求权限
        checkPermissions();
        
        // 只有在非安装完成回调的情况下才检查更新
        if ((intent == null || !"INSTALL_COMPLETE".equals(intent.getAction())) && !updateNoRemind) {
            // 检查更新
            checkForUpdates();
        }
        
        // 自动启动K歌功能 - 暂时禁用，确保滑块初始位置正确
        // if (autoStartKaraoke && checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
        //     // 延迟一点时间，确保权限检查完成
        //     android.os.Handler handler = new android.os.Handler();
        //     handler.postDelayed(new Runnable() {
        //         @Override
        //         public void run() {
        //             startAudioTest();
        //         }
        //     }, 500);
        // }
        
        // 获取系统主题模式，判断是深色还是浅色
        int currentNightMode = getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        this.isDarkMode = currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        
        // 注册系统主题变化监听器
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            getApplicationContext().registerComponentCallbacks(new android.content.ComponentCallbacks() {
                @Override
                public void onConfigurationChanged(android.content.res.Configuration newConfig) {
                    // 检测主题变化
                    int nightMode = newConfig.uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
                    boolean newIsDarkMode = nightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
                    
                    if (newIsDarkMode != isDarkMode) {
                        // 主题发生了变化，重新创建活动
                        isDarkMode = newIsDarkMode;
                        recreate();
                    }
                }
                
                @Override
                public void onLowMemory() {
                    // 低内存处理
                }
            });
        }
        
        // 根据深色模式设置颜色方案，与HTML文件保持一致
        int bgColor, cardColor, textColor, secondaryTextColor, blueColor, greenColor, redColor;
        if (isDarkMode) {
            // 深色模式 - 与HTML文件保持一致
            bgColor = Color.parseColor("#1e293b"); // slate-900
            cardColor = Color.parseColor("#334155"); // slate-700
            textColor = Color.parseColor("#ffffff");
            secondaryTextColor = Color.parseColor("#94a3b8"); // slate-400
            blueColor = Color.parseColor("#3b82f6");
            greenColor = Color.parseColor("#22c55e");
            redColor = Color.parseColor("#ef4444");
        } else {
            // 日间模式 - 与HTML文件保持一致
            bgColor = Color.parseColor("#f8fafc"); // slate-100
            cardColor = Color.parseColor("#ffffff");
            textColor = Color.parseColor("#1e293b"); // slate-800
            secondaryTextColor = Color.parseColor("#94a3b8"); // slate-400
            blueColor = Color.parseColor("#3b82f6");
            greenColor = Color.parseColor("#22c55e");
            redColor = Color.parseColor("#ef4444");
        }
        
        // 设置沉浸式状态栏
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(Color.TRANSPARENT);
            getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            );
        }
        
        // 创建主容器布局
        android.widget.LinearLayout mainContainer = new android.widget.LinearLayout(this);
        mainContainer.setOrientation(android.widget.LinearLayout.VERTICAL);
        mainContainer.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT
        ));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (isDarkMode) {
                // 深色模式
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable(
                    android.graphics.drawable.GradientDrawable.Orientation.BR_TL,
                    new int[] { Color.parseColor("#1a1c20"), Color.parseColor("#0a0a0c") }
                );
                mainContainer.setBackground(bg);
            } else {
                // 日间模式
                mainContainer.setBackgroundColor(bgColor);
            }
        } else {
            mainContainer.setBackgroundColor(bgColor);
        }
        mainContainer.setPadding(48, 48, 48, 48);
        
        // 顶部状态栏
        android.widget.LinearLayout header = new android.widget.LinearLayout(this);
        header.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        header.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        header.setWeightSum(1);
        // 根据主题设置头部背景
        if (!isDarkMode) {
            // 日间模式
            header.setBackgroundColor(Color.parseColor("#f8fafc"));
            header.setPadding(0, 0, 0, 16);
        }
        
        // 左侧标题
        android.widget.LinearLayout titleLayout = new android.widget.LinearLayout(this);
        titleLayout.setOrientation(android.widget.LinearLayout.VERTICAL);
        titleLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            0.6f
        ));
        titleLayout.setPadding(0, 0, 16, 0);
        
        // 主标题和版本号
        android.widget.LinearLayout titleRow = new android.widget.LinearLayout(this);
        titleRow.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        titleRow.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        
        TextView appTitle = new TextView(this);
        appTitle.setText("无麦K歌");
        appTitle.setTextSize(30);
        appTitle.setTypeface(null, Typeface.BOLD);
        appTitle.setTextColor(textColor);
        
        TextView versionText = new TextView(this);
        versionText.setText("v2.0.0");
        versionText.setTextSize(14);
        versionText.setTextColor(secondaryTextColor);
        versionText.setPadding(16, 0, 0, 0);
        
        TextView appDesc = new TextView(this);
        appDesc.setText("轻松K歌");
        appDesc.setTextSize(14);
        appDesc.setTextColor(secondaryTextColor);
        
        titleRow.addView(appTitle);
        titleRow.addView(versionText);
        
        titleLayout.addView(titleRow);
        titleLayout.addView(appDesc);
        
        // 右侧状态
        android.widget.LinearLayout statusLayout = new android.widget.LinearLayout(this);
        statusLayout.setOrientation(android.widget.LinearLayout.VERTICAL);
        statusLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            0.4f
        ));
        statusLayout.setGravity(android.view.Gravity.RIGHT);
        statusLayout.setPadding(0, 0, 0, 0);
        
        dateView = new TextView(this);
        dateView.setText(new SimpleDateFormat("yyyy年MM月dd日", Locale.getDefault()).format(new Date()));
        dateView.setTextSize(12);
        dateView.setTextColor(secondaryTextColor);
        
        android.widget.LinearLayout statusIndicatorLayout = new android.widget.LinearLayout(this);
        statusIndicatorLayout.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        statusIndicatorLayout.setGravity(android.view.Gravity.CENTER_VERTICAL);
        
        statusIndicator = new View(this);
        android.view.ViewGroup.MarginLayoutParams statusIndicatorParams = new android.view.ViewGroup.MarginLayoutParams(12, 12);
        statusIndicatorParams.setMargins(0, 0, 8, 0);
        statusIndicator.setLayoutParams(statusIndicatorParams);
        statusIndicator.setBackgroundColor(greenColor);
        statusIndicator.setPadding(4, 4, 4, 4);
        
        currentStatusView = new TextView(this);
        currentStatusView.setText("服务已就绪");
        currentStatusView.setTextSize(18);
        currentStatusView.setTextColor(textColor);
        
        statusIndicatorLayout.addView(statusIndicator);
        statusIndicatorLayout.addView(currentStatusView);
        
        statusLayout.addView(dateView);
        statusLayout.addView(statusIndicatorLayout);
        
        header.addView(titleLayout);
        header.addView(statusLayout);
        
        // 主内容区
        android.widget.LinearLayout contentArea = new android.widget.LinearLayout(this);
        contentArea.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        contentArea.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1
        ));
        contentArea.setWeightSum(12);
        contentArea.setPadding(0, 40, 0, 40);
        
        // 左侧：主要控制
        android.widget.LinearLayout leftArea = new android.widget.LinearLayout(this);
        leftArea.setOrientation(android.widget.LinearLayout.VERTICAL);
        leftArea.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            7
        ));
        leftArea.setPadding(0, 0, 32, 0);
        
        // 核心开关卡片
        android.widget.LinearLayout mainToggleCard = new android.widget.LinearLayout(this);
        mainToggleCard.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        mainToggleCard.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        mainToggleCard.setWeightSum(2);
        mainToggleCard.setPadding(32, 32, 32, 32);
        if (isDarkMode) {
            mainToggleCard.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，看起来更自然
            mainToggleCard.setElevation(4);
        }
        // 设置圆角和背景，与HTML文件保持一致
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (isDarkMode) {
                // 深色模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                mainToggleCard.setBackground(bg);
            } else {
                // 日间模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                mainToggleCard.setBackground(bg);
            }
            
            // 添加卡片hover效果，与HTML文件保持一致
            mainToggleCard.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, android.view.MotionEvent event) {
                    if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
                        // 按下时的效果
                        if (isDarkMode) {
                            mainToggleCard.setElevation(12);
                        } else {
                            // 日间模式 - 蓝色边框高亮
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#93c5fd")); // blue-200 边框
                            mainToggleCard.setBackground(bg);
                            mainToggleCard.setElevation(6); // 日间模式更小的hover阴影
                        }
                    } else if (event.getAction() == android.view.MotionEvent.ACTION_UP || 
                               event.getAction() == android.view.MotionEvent.ACTION_CANCEL) {
                        // 松开时的效果
                        if (isDarkMode) {
                            mainToggleCard.setElevation(8);
                        } else {
                            mainToggleCard.setElevation(4); // 恢复日间模式默认阴影
                        }
                        if (!isDarkMode) {
                            // 恢复默认边框
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                            mainToggleCard.setBackground(bg);
                        }
                    }
                    return false;
                }
            });
        } else {
            mainToggleCard.setBackgroundColor(cardColor);
        }
        
        // 左侧开关文字
        android.widget.LinearLayout toggleTextLayout = new android.widget.LinearLayout(this);
        toggleTextLayout.setOrientation(android.widget.LinearLayout.VERTICAL);
        toggleTextLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        TextView toggleTitle = new TextView(this);
        toggleTitle.setText("主控开关");
        toggleTitle.setTextSize(20);
        toggleTitle.setTypeface(null, Typeface.BOLD);
        toggleTitle.setTextColor(textColor);
        
        TextView toggleDesc = new TextView(this);
        toggleDesc.setText("唤醒车载音响系统，进入K歌模式");
        toggleDesc.setTextSize(14);
        toggleDesc.setTextColor(secondaryTextColor);
        
        toggleTextLayout.addView(toggleTitle);
        toggleTextLayout.addView(toggleDesc);
        
        // 右侧开关按钮 - 创建自定义开关容器，匹配其他开关样式但更大
        toggleContainer = new android.widget.LinearLayout(this);
        toggleContainer.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            80,
            1
        ));
        toggleContainer.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        toggleContainer.setGravity(android.view.Gravity.CENTER_VERTICAL);
        toggleContainer.setPadding(24, 0, 24, 0);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            if (isDarkMode) {
                // 深色模式 - 与自动运行开关颜色一致
                bg.setColor(Color.parseColor("#9ca3af"));
            } else {
                // 日间模式 - 与自动运行开关颜色一致
                bg.setColor(Color.parseColor("#dbeafe"));
            }
            bg.setCornerRadius(8);
            toggleContainer.setBackground(bg);
        } else {
            if (isDarkMode) {
                // 深色模式
                toggleContainer.setBackgroundColor(Color.parseColor("#9ca3af"));
            } else {
                // 日间模式
                toggleContainer.setBackgroundColor(Color.parseColor("#dbeafe"));
            }
        }
        toggleContainer.setElevation(4);
        
        mainToggleButton = new Button(this);
        mainToggleButton.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT
        ));
        mainToggleButton.setBackgroundColor(Color.TRANSPARENT);
        mainToggleButton.setElevation(0);
        mainToggleButton.setPadding(0, 0, 0, 0);
        
        toggleKnob = new View(this);
        toggleKnob.setLayoutParams(new android.view.ViewGroup.LayoutParams(64, 64));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            bg.setColor(Color.parseColor("#ffffff")); // 固定为白色
            bg.setCornerRadius(8);
            toggleKnob.setBackground(bg);
        } else {
            toggleKnob.setBackgroundColor(Color.parseColor("#ffffff")); // 固定为白色
        }
        toggleKnob.setElevation(4);
        
        mainToggleButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                if (isRecording) {
                    stopAudioTest();
                } else {
                    startAudioTest();
                }
            }
        });
        
        toggleContainer.addView(toggleKnob);
        toggleContainer.addView(mainToggleButton);
        
        mainToggleCard.addView(toggleTextLayout);
        mainToggleCard.addView(toggleContainer);
        
        // 音效调节卡片
        android.widget.LinearLayout effectsCard = new android.widget.LinearLayout(this);
        effectsCard.setOrientation(android.widget.LinearLayout.VERTICAL);
        effectsCard.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        effectsCard.setPadding(32, 32, 32, 32);
        if (isDarkMode) {
            effectsCard.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，看起来更自然
            effectsCard.setElevation(4);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (isDarkMode) {
                // 深色模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                effectsCard.setBackground(bg);
            } else {
                // 日间模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                effectsCard.setBackground(bg);
            }
            
            // 添加卡片hover效果，与HTML文件保持一致
            effectsCard.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, android.view.MotionEvent event) {
                    if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
                        // 按下时的效果
                        if (isDarkMode) {
                            effectsCard.setElevation(12);
                        } else {
                            // 日间模式 - 蓝色边框高亮
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#93c5fd")); // blue-200 边框
                            effectsCard.setBackground(bg);
                            effectsCard.setElevation(6); // 日间模式更小的hover阴影
                        }
                    } else if (event.getAction() == android.view.MotionEvent.ACTION_UP || 
                               event.getAction() == android.view.MotionEvent.ACTION_CANCEL) {
                        // 松开时的效果
                        if (isDarkMode) {
                            effectsCard.setElevation(8);
                        } else {
                            effectsCard.setElevation(4); // 恢复日间模式默认阴影
                            // 恢复默认边框
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                            effectsCard.setBackground(bg);
                        }
                    }
                    return false;
                }
            });
        } else {
            effectsCard.setBackgroundColor(cardColor);
        }
        
        TextView effectsTitle = new TextView(this);
        effectsTitle.setText("音效参数");
        effectsTitle.setTextSize(18);
        effectsTitle.setTypeface(null, Typeface.BOLD);
        effectsTitle.setTextColor(textColor);
        effectsTitle.setPadding(0, 0, 0, 32);
        
        // 增幅控制
        android.widget.LinearLayout gainControl = new android.widget.LinearLayout(this);
        gainControl.setOrientation(android.widget.LinearLayout.VERTICAL);
        gainControl.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        gainControl.setPadding(0, 0, 0, 24);
        
        android.widget.LinearLayout gainHeader = new android.widget.LinearLayout(this);
        gainHeader.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        gainHeader.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        gainHeader.setWeightSum(2);
        
        TextView gainLabelView = new TextView(this);
        gainLabelView.setText("音效增幅");
        gainLabelView.setTextSize(14);
        gainLabelView.setTextColor(secondaryTextColor);
        gainLabelView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        gainValueView = new TextView(this);
        gainValueView.setText((int)(gainLevel * 100 / 6) + "%");
        gainValueView.setTextSize(14);
        gainValueView.setTextColor(blueColor);
        gainValueView.setTypeface(Typeface.MONOSPACE);
        gainValueView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        gainValueView.setGravity(android.view.Gravity.RIGHT);
        
        gainHeader.addView(gainLabelView);
        gainHeader.addView(gainValueView);
        
        gainSeekBar = createCustomSeekBar(this, isDarkMode);
        gainSeekBar.setMax(100);
        gainSeekBar.setProgress((int)(gainLevel * 100 / 6));
        
        gainControl.addView(gainHeader);
        gainControl.addView(gainSeekBar);
        
        // 回声控制
        android.widget.LinearLayout echoControl = new android.widget.LinearLayout(this);
        echoControl.setOrientation(android.widget.LinearLayout.VERTICAL);
        echoControl.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        echoControl.setPadding(0, 0, 0, 24);
        
        android.widget.LinearLayout echoHeader = new android.widget.LinearLayout(this);
        echoHeader.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        echoHeader.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        echoHeader.setWeightSum(2);
        
        TextView echoLabelView = new TextView(this);
        echoLabelView.setText("混响回声");
        echoLabelView.setTextSize(14);
        echoLabelView.setTextColor(secondaryTextColor);
        echoLabelView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        echoValueView = new TextView(this);
        echoValueView.setText((int)(echoLevel * 100) + "%");
        echoValueView.setTextSize(14);
        echoValueView.setTextColor(blueColor);
        echoValueView.setTypeface(Typeface.MONOSPACE);
        echoValueView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        echoValueView.setGravity(android.view.Gravity.RIGHT);
        
        echoHeader.addView(echoLabelView);
        echoHeader.addView(echoValueView);
        
        echoSeekBar = createCustomSeekBar(this, isDarkMode);
        echoSeekBar.setMax(100);
        echoSeekBar.setProgress((int)(echoLevel * 100));
        
        echoControl.addView(echoHeader);
        echoControl.addView(echoSeekBar);
        
        // 延迟控制
        android.widget.LinearLayout delayControl = new android.widget.LinearLayout(this);
        delayControl.setOrientation(android.widget.LinearLayout.VERTICAL);
        delayControl.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        
        android.widget.LinearLayout delayHeader = new android.widget.LinearLayout(this);
        delayHeader.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        delayHeader.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        delayHeader.setWeightSum(2);
        
        TextView delayLabelView = new TextView(this);
        delayLabelView.setText("信号延迟");
        delayLabelView.setTextSize(14);
        delayLabelView.setTextColor(secondaryTextColor);
        delayLabelView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        delayValueView = new TextView(this);
        delayValueView.setText(delayTime + "ms");
        delayValueView.setTextSize(14);
        delayValueView.setTextColor(blueColor);
        delayValueView.setTypeface(Typeface.MONOSPACE);
        delayValueView.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        delayValueView.setGravity(android.view.Gravity.RIGHT);
        
        delayHeader.addView(delayLabelView);
        delayHeader.addView(delayValueView);
        
        delaySeekBar = createCustomSeekBar(this, isDarkMode);
        delaySeekBar.setMax(100);
        delaySeekBar.setProgress(delayTime);
        
        delayControl.addView(delayHeader);
        delayControl.addView(delaySeekBar);
        
        effectsCard.addView(effectsTitle);
        effectsCard.addView(gainControl);
        effectsCard.addView(echoControl);
        effectsCard.addView(delayControl);
        
        leftArea.addView(mainToggleCard);
        leftArea.addView(createVerticalSpacer(32));
        leftArea.addView(effectsCard);
        
        // 添加保存和恢复按钮
        android.widget.LinearLayout buttonLayout = new android.widget.LinearLayout(this);
        buttonLayout.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        buttonLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        buttonLayout.setGravity(android.view.Gravity.CENTER);
        buttonLayout.setPadding(0, 32, 0, 0);
        
        Button saveButton = new Button(this);
        saveButton.setText("保存方案");
        saveButton.setTextSize(14);
        if (isDarkMode) {
            // 深色模式 - 蓝色背景，白色文字
            saveButton.setTextColor(Color.parseColor("#ffffff"));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(blueColor);
                bg.setCornerRadius(24);
                saveButton.setBackground(bg);
            } else {
                saveButton.setBackgroundColor(blueColor);
            }
        } else {
            // 日间模式 - 与其他卡片一致的背景，蓝色文字
            saveButton.setTextColor(blueColor);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                saveButton.setBackground(bg);
            } else {
                saveButton.setBackgroundColor(cardColor);
            }
        }
        if (isDarkMode) {
            saveButton.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，与其他卡片保持一致
            saveButton.setElevation(4);
        }
        saveButton.setPadding(32, 12, 32, 12);
        android.view.ViewGroup.MarginLayoutParams saveButtonParams = new android.view.ViewGroup.MarginLayoutParams(
            android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
            android.view.ViewGroup.LayoutParams.WRAP_CONTENT
        );
        saveButtonParams.setMargins(0, 0, 16, 0);
        saveButton.setLayoutParams(saveButtonParams);
        saveButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                saveConfig();
            }
        });
        
        Button restoreButton = new Button(this);
        restoreButton.setText("恢复默认");
        restoreButton.setTextSize(14);
        if (isDarkMode) {
            // 深色模式 - 蓝色背景，白色文字
            restoreButton.setTextColor(Color.parseColor("#ffffff"));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(blueColor);
                bg.setCornerRadius(24);
                restoreButton.setBackground(bg);
            } else {
                restoreButton.setBackgroundColor(blueColor);
            }
        } else {
            // 日间模式 - 与其他卡片一致的背景，蓝色文字
            restoreButton.setTextColor(blueColor);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                restoreButton.setBackground(bg);
            } else {
                restoreButton.setBackgroundColor(cardColor);
            }
        }
        if (isDarkMode) {
            restoreButton.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，与其他卡片保持一致
            restoreButton.setElevation(4);
        }
        restoreButton.setPadding(32, 12, 32, 12);
        restoreButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                resetToDefaults();
            }
        });
        
        buttonLayout.addView(saveButton);
        buttonLayout.addView(restoreButton);
        
        leftArea.addView(buttonLayout);
        
        // 右侧：设置与信息
        android.widget.LinearLayout rightArea = new android.widget.LinearLayout(this);
        rightArea.setOrientation(android.widget.LinearLayout.VERTICAL);
        rightArea.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            5
        ));
        
        // 自动化设置
        android.widget.LinearLayout settingsCard = new android.widget.LinearLayout(this);
        settingsCard.setOrientation(android.widget.LinearLayout.VERTICAL);
        settingsCard.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        settingsCard.setPadding(32, 32, 32, 32);
        if (isDarkMode) {
            settingsCard.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，看起来更自然
            settingsCard.setElevation(4);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (isDarkMode) {
                // 深色模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                settingsCard.setBackground(bg);
            } else {
                // 日间模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                settingsCard.setBackground(bg);
            }
            
            // 添加卡片hover效果，与HTML文件保持一致
            settingsCard.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, android.view.MotionEvent event) {
                    if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
                        // 按下时的效果
                        if (isDarkMode) {
                            settingsCard.setElevation(12);
                        } else {
                            // 日间模式 - 蓝色边框高亮
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#93c5fd")); // blue-200 边框
                            settingsCard.setBackground(bg);
                            settingsCard.setElevation(6); // 日间模式更小的hover阴影
                        }
                    } else if (event.getAction() == android.view.MotionEvent.ACTION_UP || 
                               event.getAction() == android.view.MotionEvent.ACTION_CANCEL) {
                        // 松开时的效果
                        if (isDarkMode) {
                            settingsCard.setElevation(8);
                        } else {
                            settingsCard.setElevation(4); // 恢复日间模式默认阴影
                            // 恢复默认边框
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(cardColor);
                            bg.setCornerRadius(24);
                            bg.setStroke(1, Color.parseColor("#e2e8f0")); // slate-200 边框
                            settingsCard.setBackground(bg);
                        }
                    }
                    return false;
                }
            });
        } else {
            settingsCard.setBackgroundColor(cardColor);
        }
        
        TextView settingsTitle = new TextView(this);
        settingsTitle.setText("常规设置");
        settingsTitle.setTextSize(18);
        settingsTitle.setTypeface(null, Typeface.BOLD);
        settingsTitle.setTextColor(textColor);
        settingsTitle.setPadding(0, 0, 0, 32);
        
        // 自动运行选项
        android.widget.LinearLayout autoStartLayout = new android.widget.LinearLayout(this);
        autoStartLayout.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        autoStartLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        autoStartLayout.setWeightSum(2);
        autoStartLayout.setPadding(0, 0, 0, 32);
        
        android.widget.LinearLayout autoStartInfo = new android.widget.LinearLayout(this);
        autoStartInfo.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        autoStartInfo.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        // 自动运行图标
        android.widget.LinearLayout autoStartIcon = new android.widget.LinearLayout(this);
        android.view.ViewGroup.MarginLayoutParams autoStartIconParams = new android.view.ViewGroup.MarginLayoutParams(40, 40);
        autoStartIconParams.setMargins(0, 0, 16, 0);
        autoStartIcon.setLayoutParams(autoStartIconParams);
        autoStartIcon.setGravity(android.view.Gravity.CENTER);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            if (isDarkMode) {
                // 深色模式
                bg.setColor(Color.parseColor("#9ca3af"));
            } else {
                // 日间模式
                bg.setColor(Color.parseColor("#dbeafe"));
            }
            bg.setCornerRadius(12);
            autoStartIcon.setBackground(bg);
        } else {
            if (isDarkMode) {
                autoStartIcon.setBackgroundColor(Color.parseColor("#9ca3af"));
            } else {
                autoStartIcon.setBackgroundColor(Color.parseColor("#dbeafe"));
            }
        }
        
        TextView autoStartIconText = new TextView(this);
        autoStartIconText.setText("▶");
        autoStartIconText.setTextSize(16);
        if (isDarkMode) {
            // 深色模式
            autoStartIconText.setTextColor(Color.parseColor("#ffffff"));
        } else {
            // 日间模式 - 显示蓝色文本
            autoStartIconText.setTextColor(Color.parseColor("#3b82f6"));
        }
        autoStartIcon.addView(autoStartIconText);
        
        android.widget.LinearLayout autoStartText = new android.widget.LinearLayout(this);
        autoStartText.setOrientation(android.widget.LinearLayout.VERTICAL);
        autoStartText.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        
        TextView autoStartTitle = new TextView(this);
        autoStartTitle.setText("自动运行");
        autoStartTitle.setTextSize(16);
        autoStartTitle.setTextColor(textColor);
        
        TextView autoStartDesc = new TextView(this);
        autoStartDesc.setText("软件开启时自动开始K歌");
        autoStartDesc.setTextSize(12);
        autoStartDesc.setTextColor(secondaryTextColor);
        
        autoStartText.addView(autoStartTitle);
        autoStartText.addView(autoStartDesc);
        autoStartInfo.addView(autoStartIcon);
        autoStartInfo.addView(autoStartText);
        
        android.widget.Switch autoStartSwitch = new android.widget.Switch(this);
        autoStartSwitch.setChecked(autoStartKaraoke);
        autoStartSwitch.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        autoStartSwitch.setGravity(android.view.Gravity.RIGHT);
        autoStartSwitch.setOnCheckedChangeListener(new android.widget.CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(android.widget.CompoundButton buttonView, boolean isChecked) {
                autoStartKaraoke = isChecked;
                Log.i(TAG, "自动开始K歌设置为: " + autoStartKaraoke);
            }
        });
        
        // 自定义自动运行开关样式
        customizeSwitch(autoStartSwitch);
        
        autoStartLayout.addView(autoStartInfo);
        autoStartLayout.addView(autoStartSwitch);
        
        // 勿扰模式选项
        android.widget.LinearLayout doNotDisturbLayout = new android.widget.LinearLayout(this);
        doNotDisturbLayout.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        doNotDisturbLayout.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        doNotDisturbLayout.setWeightSum(2);
        
        android.widget.LinearLayout doNotDisturbInfo = new android.widget.LinearLayout(this);
        doNotDisturbInfo.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        doNotDisturbInfo.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        // 勿扰模式图标
        android.widget.LinearLayout doNotDisturbIcon = new android.widget.LinearLayout(this);
        android.view.ViewGroup.MarginLayoutParams doNotDisturbIconParams = new android.view.ViewGroup.MarginLayoutParams(40, 40);
        doNotDisturbIconParams.setMargins(0, 0, 16, 0);
        doNotDisturbIcon.setLayoutParams(doNotDisturbIconParams);
        doNotDisturbIcon.setGravity(android.view.Gravity.CENTER);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            if (isDarkMode) {
                // 深色模式
                bg.setColor(Color.parseColor("#9ca3af"));
            } else {
                // 日间模式
                bg.setColor(Color.parseColor("#fed7aa"));
            }
            bg.setCornerRadius(12);
            doNotDisturbIcon.setBackground(bg);
        } else {
            if (isDarkMode) {
                doNotDisturbIcon.setBackgroundColor(Color.parseColor("#9ca3af"));
            } else {
                doNotDisturbIcon.setBackgroundColor(Color.parseColor("#fed7aa"));
            }
        }
        
        TextView doNotDisturbIconText = new TextView(this);
        doNotDisturbIconText.setText("🔇");
        doNotDisturbIconText.setTextSize(16);
        if (isDarkMode) {
            // 深色模式
            doNotDisturbIconText.setTextColor(Color.parseColor("#ffffff"));
        } else {
            // 日间模式 - 显示橙色文本
            doNotDisturbIconText.setTextColor(Color.parseColor("#f59e0b"));
        }
        doNotDisturbIcon.addView(doNotDisturbIconText);
        
        android.widget.LinearLayout doNotDisturbText = new android.widget.LinearLayout(this);
        doNotDisturbText.setOrientation(android.widget.LinearLayout.VERTICAL);
        doNotDisturbText.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        
        TextView doNotDisturbTitle = new TextView(this);
        doNotDisturbTitle.setText("勿扰模式");
        doNotDisturbTitle.setTextSize(16);
        doNotDisturbTitle.setTextColor(textColor);
        
        TextView doNotDisturbDesc = new TextView(this);
        doNotDisturbDesc.setText("关闭更新及版本提醒");
        doNotDisturbDesc.setTextSize(12);
        doNotDisturbDesc.setTextColor(secondaryTextColor);
        
        doNotDisturbText.addView(doNotDisturbTitle);
        doNotDisturbText.addView(doNotDisturbDesc);
        doNotDisturbInfo.addView(doNotDisturbIcon);
        doNotDisturbInfo.addView(doNotDisturbText);
        
        android.widget.Switch doNotDisturbSwitch = new android.widget.Switch(this);
        doNotDisturbSwitch.setChecked(updateNoRemind);
        doNotDisturbSwitch.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            0,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        doNotDisturbSwitch.setGravity(android.view.Gravity.RIGHT);
        doNotDisturbSwitch.setOnCheckedChangeListener(new android.widget.CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(android.widget.CompoundButton buttonView, boolean isChecked) {
                updateNoRemind = isChecked;
                Log.i(TAG, "更新不再提示设置为: " + updateNoRemind);
            }
        });
        
        // 自定义勿扰模式开关样式
        customizeSwitch(doNotDisturbSwitch);
        
        doNotDisturbLayout.addView(doNotDisturbInfo);
        doNotDisturbLayout.addView(doNotDisturbSwitch);
        
        settingsCard.addView(settingsTitle);
        settingsCard.addView(autoStartLayout);
        settingsCard.addView(doNotDisturbLayout);
        
        // 关于区域
        android.widget.LinearLayout aboutCard = new android.widget.LinearLayout(this);
        aboutCard.setOrientation(android.widget.LinearLayout.VERTICAL);
        aboutCard.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        aboutCard.setPadding(32, 32, 32, 32);
        if (isDarkMode) {
            aboutCard.setElevation(8);
        } else {
            // 日间模式 - 更小的阴影，看起来更自然
            aboutCard.setElevation(4);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (isDarkMode) {
                // 深色模式 - 与HTML文件保持一致
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(cardColor);
                bg.setCornerRadius(24);
                aboutCard.setBackground(bg);
            } else {
                // 日间模式 - 与HTML文件保持一致，使用蓝色背景
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(Color.parseColor("#3b82f6")); // blue-600
                bg.setCornerRadius(24);
                aboutCard.setBackground(bg);
            }
            
            // 添加卡片hover效果，与HTML文件保持一致
            aboutCard.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, android.view.MotionEvent event) {
                    if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
                        // 按下时的效果
                        if (isDarkMode) {
                            aboutCard.setElevation(12);
                        } else {
                            aboutCard.setElevation(6); // 日间模式更小的hover阴影
                        }
                        if (!isDarkMode) {
                            // 日间模式 - 蓝色背景高亮
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(Color.parseColor("#2563eb")); // blue-700
                            bg.setCornerRadius(24);
                            aboutCard.setBackground(bg);
                        }
                    } else if (event.getAction() == android.view.MotionEvent.ACTION_UP || 
                               event.getAction() == android.view.MotionEvent.ACTION_CANCEL) {
                        // 松开时的效果
                        if (isDarkMode) {
                            aboutCard.setElevation(8);
                        } else {
                            aboutCard.setElevation(4); // 恢复日间模式默认阴影
                        }
                        if (!isDarkMode) {
                            // 恢复默认背景
                            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                            bg.setColor(Color.parseColor("#3b82f6")); // blue-600
                            bg.setCornerRadius(24);
                            aboutCard.setBackground(bg);
                        }
                    }
                    return false;
                }
            });
        } else {
            if (isDarkMode) {
                aboutCard.setBackgroundColor(cardColor);
            } else {
                aboutCard.setBackgroundColor(Color.parseColor("#3b82f6"));
            }
        }
        

        
        android.widget.LinearLayout aboutText = new android.widget.LinearLayout(this);
        aboutText.setOrientation(android.widget.LinearLayout.VERTICAL);
        aboutText.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
        ));
        aboutText.setPadding(0, 0, 0, 0);
        aboutText.setElevation(8); // 设置Z轴高度，确保文字显示在背景图片上方
        
        TextView aboutTitle = new TextView(this);
        aboutTitle.setText("关于软件");
        aboutTitle.setTextSize(18);
        aboutTitle.setTypeface(null, Typeface.BOLD);
        if (isDarkMode) {
            aboutTitle.setTextColor(textColor);
        } else {
            // 日间模式 - 蓝色背景显示白色文本，与HTML文件保持一致
            aboutTitle.setTextColor(Color.parseColor("#ffffff"));
        }
        
        TextView aboutDesc = new TextView(this);
        aboutDesc.setText("本应用由邪恶银渐层@小红书，先天BUG圣体@懂车帝制作");
        aboutDesc.setTextSize(14);
        if (isDarkMode) {
            aboutDesc.setTextColor(secondaryTextColor);
        } else {
            // 日间模式 - 蓝色背景显示浅蓝色文本，与HTML文件保持一致
            aboutDesc.setTextColor(Color.parseColor("#dbeafe")); // blue-100
        }
        aboutDesc.setPadding(0, 8, 0, 16);
        
        Button checkVersionButton = new Button(this);
        checkVersionButton.setText("检查版本");
        checkVersionButton.setTextSize(12);
        if (isDarkMode) {
            checkVersionButton.setTextColor(blueColor);
            checkVersionButton.setBackgroundColor(Color.TRANSPARENT);
        } else {
            // 日间模式 - 淡蓝色背景显示深蓝色文本
            checkVersionButton.setTextColor(Color.parseColor("#1e40af")); // blue-800 深蓝色
            checkVersionButton.setBackgroundColor(Color.parseColor("#dbeafe")); // blue-100 淡蓝色
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                bg.setColor(Color.parseColor("#dbeafe")); // blue-100 淡蓝色
                bg.setCornerRadius(12);
                bg.setStroke(1, Color.parseColor("#bfdbfe")); // blue-200 边框
                checkVersionButton.setBackground(bg);
            }
        }
        checkVersionButton.setPadding(16, 8, 16, 8);
        checkVersionButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                checkForUpdates();
            }
        });
        
        aboutText.addView(aboutTitle);
        aboutText.addView(aboutDesc);
        aboutText.addView(checkVersionButton);
        
        aboutCard.addView(aboutText);
        
        rightArea.addView(settingsCard);
        rightArea.addView(createVerticalSpacer(32));
        rightArea.addView(aboutCard);
        
        contentArea.addView(leftArea);
        contentArea.addView(rightArea);
        
        mainContainer.addView(header);
        mainContainer.addView(contentArea);
        
        // 为控制条添加监听
        delaySeekBar.setOnSeekBarChangeListener(new android.widget.SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(android.widget.SeekBar seekBar, int progress, boolean fromUser) {
                delayTime = progress;
                delayValueView.setText(delayTime + "ms");
                Log.i(TAG, "延迟时间设置为: " + delayTime + "ms");
            }
            @Override
            public void onStartTrackingTouch(android.widget.SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(android.widget.SeekBar seekBar) {}
        });
        
        echoSeekBar.setOnSeekBarChangeListener(new android.widget.SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(android.widget.SeekBar seekBar, int progress, boolean fromUser) {
                echoLevel = progress / 100.0f;
                echoValueView.setText(progress + "%");
                Log.i(TAG, "回声强度设置为: " + echoLevel);
            }
            @Override
            public void onStartTrackingTouch(android.widget.SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(android.widget.SeekBar seekBar) {}
        });
        
        gainSeekBar.setOnSeekBarChangeListener(new android.widget.SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(android.widget.SeekBar seekBar, int progress, boolean fromUser) {
                gainLevel = (progress * 6.0f) / 100.0f;
                gainValueView.setText(progress + "%");
                Log.i(TAG, "总增益设置为: " + gainLevel + "倍");
            }
            @Override
            public void onStartTrackingTouch(android.widget.SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(android.widget.SeekBar seekBar) {}
        });
        
        // 设置主容器为内容视图
        setContentView(mainContainer);
        
        // 立即设置滑块的初始位置，确保在所有可能影响滑块位置的操作之前执行
        toggleContainer.post(new Runnable() {
            @Override
            public void run() {
                // 重新创建toggleContainer，确保没有其他视图影响滑块位置
                android.widget.LinearLayout newToggleContainer = new android.widget.LinearLayout(MainActivity.this);
                newToggleContainer.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
                    0,
                    80,
                    1
                ));
                newToggleContainer.setOrientation(android.widget.LinearLayout.HORIZONTAL);
                newToggleContainer.setGravity(android.view.Gravity.CENTER_VERTICAL);
                newToggleContainer.setPadding(24, 0, 24, 0);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                    if (isDarkMode) {
                        // 深色模式 - 与自动运行开关颜色一致
                        bg.setColor(Color.parseColor("#9ca3af"));
                    } else {
                        // 日间模式 - 与自动运行开关颜色一致
                        bg.setColor(Color.parseColor("#dbeafe"));
                    }
                    bg.setCornerRadius(8);
                    newToggleContainer.setBackground(bg);
                } else {
                    if (isDarkMode) {
                        // 深色模式
                        newToggleContainer.setBackgroundColor(Color.parseColor("#9ca3af"));
                    } else {
                        // 日间模式
                        newToggleContainer.setBackgroundColor(Color.parseColor("#dbeafe"));
                    }
                }
                
                // 创建新的toggleKnob
                View newToggleKnob = new View(MainActivity.this);
                newToggleKnob.setLayoutParams(new android.view.ViewGroup.LayoutParams(64, 64));
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
                    bg.setColor(Color.parseColor("#ffffff")); // 固定为白色
                    bg.setCornerRadius(8);
                    newToggleKnob.setBackground(bg);
                } else {
                    newToggleKnob.setBackgroundColor(Color.parseColor("#ffffff")); // 固定为白色
                }
                newToggleKnob.setElevation(4);
                
                // 添加点击事件
                newToggleContainer.setOnClickListener(new View.OnClickListener() {
                    public void onClick(View v) {
                        if (isRecording) {
                            stopAudioTest();
                        } else {
                            startAudioTest();
                        }
                    }
                });
                
                // 添加toggleKnob到新的容器
                newToggleContainer.addView(newToggleKnob);
                
                // 保存引用
                toggleContainer = newToggleContainer;
                toggleKnob = newToggleKnob;
                
                // 替换旧的toggleContainer
                mainToggleCard.removeViewAt(1); // 移除旧的toggleContainer
                mainToggleCard.addView(newToggleContainer); // 添加新的toggleContainer
                
                // 设置滑块的初始位置为最左边
                toggleKnob.setTranslationX(0); // 从最左边开始
            }
        });
        
        // 启动自动日期更新
        startDateUpdater();
        
        // 注册广播接收器，接收悬浮窗发送的停止K歌命令
        android.content.IntentFilter filter = new android.content.IntentFilter();
        filter.addAction("com.car.karake.STOP_KARAOKE");
        registerReceiver(stopKaraokeReceiver, filter);
        
        Log.i(TAG, "UI初始化完成，准备开始音频测试");
    }
    
    /**
     * 启动自动日期更新
     */
    private void startDateUpdater() {
        new android.os.Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (dateView != null) {
                    dateView.setText(new SimpleDateFormat("yyyy年MM月dd日", Locale.getDefault()).format(new Date()));
                }
                // 每分钟更新一次
                startDateUpdater();
            }
        }, 60000);
    }
    
    /**
     * 自定义开关样式，设置更亮的关闭状态颜色
     */
    private void customizeSwitch(android.widget.Switch switchView) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            switchView.getThumbDrawable().setColorFilter(
                Color.WHITE,
                android.graphics.PorterDuff.Mode.SRC_IN
            );
            if (switchView.isChecked()) {
                switchView.getTrackDrawable().setColorFilter(
                    Color.parseColor("#3b82f6"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                );
            } else {
                switchView.getTrackDrawable().setColorFilter(
                    Color.parseColor("#6b7280"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                );
            }
            switchView.setOnCheckedChangeListener(new android.widget.CompoundButton.OnCheckedChangeListener() {
                @Override
                public void onCheckedChanged(android.widget.CompoundButton buttonView, boolean isChecked) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && buttonView instanceof android.widget.Switch) {
                        android.widget.Switch switchBtn = (android.widget.Switch) buttonView;
                        if (isChecked) {
                            switchBtn.getTrackDrawable().setColorFilter(
                                Color.parseColor("#3b82f6"),
                                android.graphics.PorterDuff.Mode.SRC_IN
                            );
                        } else {
                            switchBtn.getTrackDrawable().setColorFilter(
                                Color.parseColor("#6b7280"),
                                android.graphics.PorterDuff.Mode.SRC_IN
                            );
                        }
                    }
                }
            });
        }
    }
    
    private void startAudioTest() {
        // 检查是否已经在录制，如果是则直接返回，避免重复初始化
        if (isRecording) {
            addLog(TAG, "已经在K歌中，无需重复开始");
            Log.i(TAG, "已经在K歌中，无需重复开始");
            return;
        }
        
        addLog(TAG, "开始K歌，初始化AudioRecord和AudioTrack");
        Log.i(TAG, "开始K歌，初始化AudioRecord和AudioTrack");
        
        // 更新UI状态
        if (currentStatusView != null) {
            currentStatusView.setText("正在K歌...");
            currentStatusView.setTextColor(Color.parseColor("#3b82f6"));
        }
        if (statusIndicator != null) {
            statusIndicator.setBackgroundColor(Color.parseColor("#ef4444"));
        }
        if (toggleContainer != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            bg.setColor(Color.parseColor("#3b82f6"));
            bg.setCornerRadius(8);
            toggleContainer.setBackground(bg);
        }
        if (toggleKnob != null) {
            toggleKnob.animate()
                .translationX(toggleContainer.getWidth() - 64 - 8)
                .setDuration(300)
                .setStartDelay(0)
                .start();
        }
        
        // 显示无麦K歌已打开的提示
        Toast.makeText(this, "无麦K歌已打开", Toast.LENGTH_SHORT).show();
        
        // 不主动请求音频焦点，改为使用音频属性标记，让系统智能处理
        // 这样可以确保其他音乐应用能够继续播放
        Log.i(TAG, "使用智能音频处理，允许其他音乐继续播放");
        
        // 初始化AudioRecord - 优化延迟
        try {
            // 使用AudioSource.VOICE_COMMUNICATION获取更好的语音质量和更低的延迟
            int audioSource = MediaRecorder.AudioSource.VOICE_COMMUNICATION;
            
            // 检查是否支持低延迟音频
            AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
            
            // 尝试获取系统音频延迟信息（仅在较新版本Android支持）
            try {
                String latencyMode = (String) AudioManager.class.getField("PROPERTY_OUTPUT_LATENCY").get(null);
                String latency = audioManager.getProperty(latencyMode);
                Log.i(TAG, "系统音频延迟: " + latency + "ms");
            } catch (Exception e) {
                Log.i(TAG, "系统不支持获取音频延迟信息");
            }
            
            // 使用传统方式初始化AudioRecord，确保兼容性
            audioRecord = new AudioRecord(
                audioSource,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                BUFFER_SIZE
            );
            
            Log.i(TAG, "AudioRecord初始化成功，使用低延迟设置");
        } catch (Exception e) {
            Log.e(TAG, "AudioRecord初始化失败: " + e.getMessage());
            return;
        }
        
        // 初始化AudioTrack，使用音乐流，确保从所有音响播放 - 优化延迟
        try {
            // 使用选择的输出声道配置
            int outputChannelConfig = this.outputChannelConfig;
            
            // 使用传统方式初始化AudioTrack，确保兼容性
            audioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC, // 使用音乐流，确保从所有音响播放
                SAMPLE_RATE,
                outputChannelConfig,
                AUDIO_FORMAT,
                BUFFER_SIZE,
                AudioTrack.MODE_STREAM
            );
            
            // 尝试设置低延迟模式（仅在较新版本Android支持）
            try {
                AudioTrack.class.getMethod("setPerformanceMode", int.class)
                    .invoke(audioTrack, AudioTrack.class.getField("PERFORMANCE_MODE_LOW_LATENCY").get(null));
                Log.i(TAG, "AudioTrack初始化成功，低延迟模式已启用");
            } catch (Exception e) {
                Log.i(TAG, "AudioTrack初始化成功，系统不支持低延迟模式");
            }
            
            Log.i(TAG, "AudioTrack初始化成功，使用音乐流从所有音响播放，输出声道: 单声道");
        } catch (Exception e) {
            Log.e(TAG, "AudioTrack初始化失败: " + e.getMessage());
            audioRecord.release();
            return;
        }
        
        // 初始化延迟缓冲区
        delayBufferSize = (int)(SAMPLE_RATE * delayTime / 1000.0f);
        if (delayTime > 0) {
            delayBuffer = new float[delayBufferSize];
            delayBufferIndex = 0;
        } else {
            delayBuffer = null;
            delayBufferSize = 0;
        }
        
        // 开始录制和播放
        isRecording = true;
        audioRecord.startRecording();
        audioTrack.play();
        
        // 检查悬浮窗权限并启动悬浮窗服务
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Settings.canDrawOverlays(this)) {
                Log.i(TAG, "启动悬浮窗服务");
                Intent floatingIntent = new Intent(this, FloatingWindowService.class);
                startService(floatingIntent);
            } else {
                Log.w(TAG, "悬浮窗权限未授予，无法显示停止按钮");
                Toast.makeText(this, "悬浮窗权限未授予，无法显示停止按钮", Toast.LENGTH_LONG).show();
            }
        }
        
        Log.i(TAG, "开始录制和播放音频，延迟缓冲区大小: " + delayBufferSize);
        
        // 创建录音线程
        recordingThread = new Thread(new Runnable() {
            public void run() {
                Log.i(TAG, "录音线程已启动，开始初始化音频缓冲区");
                byte[] buffer = new byte[BUFFER_SIZE];
                
                // 性能统计
                long totalReadTime = 0;
                long totalProcessTime = 0;
                long totalWriteTime = 0;
                long frameCount = 0;
                long lastLogTime = System.currentTimeMillis();
                
                Log.i(TAG, "录音线程初始化完成，开始处理音频数据");
                
                while (isRecording) {
                    try {
                        // 从麦克风读取音频数据
                        long readStart = System.nanoTime();
                        int readBytes = audioRecord.read(buffer, 0, buffer.length);
                        long readEnd = System.nanoTime();
                        long readTime = readEnd - readStart;
                        totalReadTime += readTime;
                        
                        if (readBytes > 0) {
                            frameCount++;
                            
                            // 处理音频效果：延迟、回声和增幅
                            long processStart = System.nanoTime();
                            processAudio(buffer, readBytes);
                            long processEnd = System.nanoTime();
                            long processTime = processEnd - processStart;
                            totalProcessTime += processTime;
                            
                            // 播放音频数据
                            long writeStart = System.nanoTime();
                            int writeBytes = audioTrack.write(buffer, 0, readBytes);
                            long writeEnd = System.nanoTime();
                            long writeTime = writeEnd - writeStart;
                            totalWriteTime += writeTime;
                            
                            // 每10帧或1秒输出一次性能统计，确保能看到数据
                            if (frameCount % 10 == 0 || (System.currentTimeMillis() - lastLogTime) > 1000) {
                                double avgReadTime = (double)totalReadTime / frameCount / 1000.0; // 微秒
                                double avgProcessTime = (double)totalProcessTime / frameCount / 1000.0; // 微秒
                                double avgWriteTime = (double)totalWriteTime / frameCount / 1000.0; // 微秒
                                double totalFrameTime = avgReadTime + avgProcessTime + avgWriteTime;
                                
                                Log.i(TAG, "音频处理性能统计 - 读取: " + String.format("%.2f", avgReadTime) + "μs, 处理: " + String.format("%.2f", avgProcessTime) + "μs, 写入: " + String.format("%.2f", avgWriteTime) + "μs, 总帧时间: " + String.format("%.2f", totalFrameTime) + "μs, 帧率: " + frameCount);
                                
                                // 重置统计
                                totalReadTime = 0;
                                totalProcessTime = 0;
                                totalWriteTime = 0;
                                frameCount = 0;
                                lastLogTime = System.currentTimeMillis();
                            }
                        } else {
                            Log.w(TAG, "从麦克风读取音频数据失败，读取字节数: " + readBytes);
                        }
                    } catch (Exception e) {
                        Log.e(TAG, "音频处理失败: " + e.getMessage());
                        e.printStackTrace();
                        break;
                    }
                }
                
                Log.i(TAG, "录音线程已停止");
            }
        });
        
        // 设置线程优先级为最高，确保实时性
        recordingThread.setPriority(Thread.MAX_PRIORITY);
        recordingThread.start();
        Log.i(TAG, "音频测试线程启动，优先级已设置为最高");
    }
    
    private void stopAudioTest() {
        addLog(TAG, "停止K歌");
        Log.i(TAG, "停止K歌");
        
        // 显示无麦K歌已关闭的提示
        Toast.makeText(this, "无麦K歌已关闭", Toast.LENGTH_SHORT).show();
        
        isRecording = false;
        
        // 更新UI状态
        if (currentStatusView != null) {
            currentStatusView.setText("服务已就绪");
            if (isDarkMode) {
                currentStatusView.setTextColor(Color.parseColor("#ffffff"));
            } else {
                currentStatusView.setTextColor(Color.parseColor("#1e293b")); // slate-800，与白天模式文本颜色一致
            }
        }
        if (statusIndicator != null) {
            statusIndicator.setBackgroundColor(Color.parseColor("#22c55e"));
        }
        if (toggleContainer != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
            if (isDarkMode) {
                // 深色模式 - 与自动运行开关颜色一致
                bg.setColor(Color.parseColor("#9ca3af"));
            } else {
                // 日间模式 - 与自动运行开关颜色一致
                bg.setColor(Color.parseColor("#dbeafe"));
            }
            bg.setCornerRadius(8);
            toggleContainer.setBackground(bg);
        }
        if (toggleKnob != null) {
            toggleKnob.animate()
                .translationX(8)
                .setDuration(300)
                .setStartDelay(0)
                .start();
        }
        
        // 停止悬浮窗服务
        Log.i(TAG, "停止悬浮窗服务");
        Intent floatingIntent = new Intent(this, FloatingWindowService.class);
        stopService(floatingIntent);
        
        if (recordingThread != null) {
            try {
                // 设置超时时间，避免线程无限等待
                recordingThread.join(5000); // 5秒超时
                if (recordingThread.isAlive()) {
                    Log.w(TAG, "线程停止超时，强制中断");
                    recordingThread.interrupt();
                }
                Log.i(TAG, "K歌线程已停止");
            } catch (InterruptedException e) {
                Log.e(TAG, "线程停止失败: " + e.getMessage());
            } finally {
                recordingThread = null;
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
     * 更新延迟缓冲区大小
     */
    private void updateDelayBuffer() {
        // 计算新的延迟缓冲区大小
        int newDelayBufferSize = (int)(SAMPLE_RATE * delayTime / 1000.0f);
        
        // 如果大小变化，重新创建缓冲区
        if (delayBufferSize != newDelayBufferSize) {
            delayBufferSize = newDelayBufferSize;
            delayBuffer = new float[delayBufferSize];
            delayBufferIndex = 0;
            Log.i(TAG, "延迟缓冲区已更新，新大小: " + delayBufferSize);
        }
    }
    
    /**
     * 单极点低通滤波器，用于减少高频嘶嘶声
     * @param input 当前输入样本
     * @param channelIndex 声道索引 (0或1)
     * @return 滤波后的样本
     */
    private float lowpassFilter(float input, int channelIndex) {
        // 计算滤波系数
        float RC = 1.0f / (2 * (float)Math.PI * LOWPASS_CUTOFF);
        float dt = 1.0f / SAMPLE_RATE;
        float alpha = dt / (RC + dt);
        
        // 应用滤波
        lowpassHistory[channelIndex] = lowpassHistory[channelIndex] + alpha * (input - lowpassHistory[channelIndex]);
        return lowpassHistory[channelIndex];
    }
    
    /**
     * 处理音频效果：延迟、回声和增幅
     * @param buffer 包含16位PCM样本的音频缓冲区
     * @param readBytes 读取的字节数
     */
    private void processAudio(byte[] buffer, int readBytes) {
        // 检查是否需要延迟和回声处理
        boolean needDelayEcho = delayTime > 0 && delayBuffer != null && delayBufferSize > 0;
        
        // 只有当需要时才更新延迟缓冲区（预先更新，避免在循环中频繁调用）
        if (needDelayEcho) {
            updateDelayBuffer();
        }
        
        // 直接处理单声道音频数据
        for (int i = 0; i < readBytes; i += 2) {
            // 读取样本
            short sample = (short) ((buffer[i] & 0xFF) | (buffer[i + 1] << 8));
            float floatSample = sample;
            
            // 应用低通滤波减少嘶嘶声
            float filteredSample = lowpassFilter(floatSample, 0);
            
            // 应用音频效果
            if (needDelayEcho) {
                // 计算延迟索引
                int delayedIndex = (delayBufferIndex - delayBufferSize + delayBuffer.length) % delayBuffer.length;
                delayedIndex = delayedIndex < 0 ? delayedIndex + delayBuffer.length : delayedIndex;
                
                // 混合延迟效果
                float delayedSample = delayBuffer[delayedIndex];
                filteredSample += delayedSample * echoLevel;
                
                // 将当前样本存入延迟缓冲区
                delayBuffer[delayBufferIndex] = sample; // 存储原始样本，减少一次转换
                delayBufferIndex = (delayBufferIndex + 1) % delayBuffer.length;
            }
            
            // 应用增益并使用软限幅减少数字噪声
            float processed = filteredSample * gainLevel;
            // 软限幅，减少削波失真
            if (processed > 32767.0f) processed = 32767.0f - 0.1f;
            if (processed < -32768.0f) processed = -32768.0f + 0.1f;
            short processedSample = (short)processed;
            
            // 写回缓冲区
            buffer[i] = (byte) (processedSample & 0xFF);
            buffer[i + 1] = (byte) ((processedSample >> 8) & 0xFF);
        }
    }
    
    /**
     * 加载保存的配置
     */
    private void loadConfig() {
        Log.i(TAG, "加载保存的配置");
        
        // 加载声道配置
        currentChannelIndex = sharedPreferences.getInt("currentChannelIndex", 0);
        CHANNEL_CONFIG = channelConfigs[currentChannelIndex];
        
        // 加载延迟、回声和增益设置
        delayTime = sharedPreferences.getInt("delayTime", 0); // 默认0ms延迟
        echoLevel = sharedPreferences.getFloat("echoLevel", 0.0f); // 默认0%回声强度
        gainLevel = sharedPreferences.getFloat("gainLevel", 1.8f); // 默认1.8倍增益（30%增幅），平衡音量和噪声
        
        // 加载新的配置选项
        autoStartKaraoke = sharedPreferences.getBoolean("autoStartKaraoke", false); // 默认不自动开始K歌
        updateNoRemind = sharedPreferences.getBoolean("updateNoRemind", false); // 默认提示更新
        
        Log.i(TAG, "配置加载完成: 声道=" + channelNames[currentChannelIndex] + ", 延迟=" + delayTime + "ms, 回声=" + (int)(echoLevel * 100) + "%, 增益=" + gainLevel + "倍");
        Log.i(TAG, "自动开始K歌: " + autoStartKaraoke + ", 更新不再提示: " + updateNoRemind);
    }
    
    /**
     * 保存当前配置
     */
    private void saveConfig() {
        Log.i(TAG, "保存当前配置");
        
        // 保存声道配置
        android.content.SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putInt("currentChannelIndex", currentChannelIndex);
        
        // 保存延迟、回声和增益设置
        editor.putInt("delayTime", delayTime);
        editor.putFloat("echoLevel", echoLevel);
        editor.putFloat("gainLevel", gainLevel);
        
        // 保存新的配置选项
        editor.putBoolean("autoStartKaraoke", autoStartKaraoke);
        editor.putBoolean("updateNoRemind", updateNoRemind);
        
        // 提交保存
        editor.apply();
        
        Log.i(TAG, "配置保存完成: 声道=" + channelNames[currentChannelIndex] + ", 延迟=" + delayTime + "ms, 回声=" + (int)(echoLevel * 100) + "%, 增益=" + gainLevel + "倍");
        Log.i(TAG, "自动开始K歌: " + autoStartKaraoke + ", 更新不再提示: " + updateNoRemind);
        
        // 显示保存成功提示
        Toast.makeText(this, "配置已保存", Toast.LENGTH_SHORT).show();
    }
    
    /**
     * 恢复默认设置
     */
    private void resetToDefaults() {
        // 恢复默认设置
        delayTime = 0; // 默认0ms延迟
        echoLevel = 0.0f; // 默认0%回声强度
        gainLevel = 1.8f; // 默认1.8倍增益（30%增幅），平衡音量和噪声
        currentChannelIndex = 0;
        CHANNEL_CONFIG = channelConfigs[currentChannelIndex];
        
        // 重置新的配置选项
        autoStartKaraoke = true; // 默认自动开始K歌
        updateNoRemind = false; // 默认提示更新
        
        // 更新控制条位置
        if (delaySeekBar != null) {
            delaySeekBar.setProgress(delayTime);
        }
        if (echoSeekBar != null) {
            echoSeekBar.setProgress((int)(echoLevel * 100));
        }
        if (gainSeekBar != null) {
            gainSeekBar.setProgress((int)((gainLevel - 1) * 100));
        }
        
        // 更新标签显示
        if (delayLabel != null) {
            delayLabel.setText("延迟: " + delayTime + "ms");
        }
        if (echoLabel != null) {
            echoLabel.setText("回声: " + (int)(echoLevel * 100) + "%");
        }
        if (gainLabel != null) {
            gainLabel.setText("增幅: " + String.format("%.1f", gainLevel) + "倍");
        }
        
        Log.i(TAG, "已恢复默认音频设置");
        Log.i(TAG, "已恢复默认配置选项: 自动开始K歌=" + autoStartKaraoke + ", 更新不再提示=" + updateNoRemind);
        
        // 重置延迟缓冲区
        delayBuffer = null;
        delayBufferSize = 0;
        delayBufferIndex = 0;
    }
    

    
    private void showAboutDialog() {
        // 获取系统主题模式，保持对话框与系统主题一致
        int currentNightMode = getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkMode = currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("关于车机无麦K歌");
        
        // 更新关于信息，按照要求修改
        String aboutMessage = "- 版本号：1.0.8 \n\n"
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
        
        // 注销广播接收器
        try {
            unregisterReceiver(stopKaraokeReceiver);
        } catch (IllegalArgumentException e) {
            Log.w(TAG, "广播接收器未注册或已注销");
        }
        
        Log.i(TAG, "应用销毁，音频资源已释放");
    }
    
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        
        // 处理安装完成回调
        if (intent != null && "INSTALL_COMPLETE".equals(intent.getAction())) {
            Log.i(TAG, "收到安装完成回调(onNewIntent)，跳过更新检查");
            // 延迟一段时间后检查安装状态
            new android.os.Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    checkInstallationStatus();
                }
            }, 2000);
            return;
        }
        
        // 处理从悬浮窗传递过来的停止K歌意图
        if (intent != null && intent.getBooleanExtra("STOP_KARAOKE", false)) {
            Log.i(TAG, "收到来自悬浮窗的停止K歌请求");
            stopAudioTest();
        }
    }
    
    // 检查和请求权限
    private void checkPermissions() {
        Log.i(TAG, "检查权限");
        
        // 检查录音权限
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "录音权限未授予，正在请求");
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, REQUEST_RECORD_AUDIO_PERMISSION);
        } else {
            Log.i(TAG, "录音权限已授予");
        }
        
        // 检查存储权限 - 使用兼容性更好的旧版权限
        if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "存储权限未授予，正在请求");
            requestPermissions(new String[]{
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE
            }, REQUEST_STORAGE_PERMISSION);
        } else {
            Log.i(TAG, "存储权限已授予");
        }
        
        // 检查悬浮窗权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "悬浮窗权限未授予，正在请求");
                Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName()));
                startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION);
            } else {
                Log.i(TAG, "悬浮窗权限已授予");
            }
        }
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.i(TAG, "录音权限已授予");
            } else {
                Log.e(TAG, "录音权限被拒绝，应用无法正常工作");
                Toast.makeText(this, "录音权限被拒绝，应用无法正常工作", Toast.LENGTH_LONG).show();
            }
        } else if (requestCode == REQUEST_STORAGE_PERMISSION) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                Log.i(TAG, "存储权限已授予");
            } else {
                Log.e(TAG, "部分或全部存储权限被拒绝");
                Toast.makeText(this, "部分或全部存储权限被拒绝，某些功能可能无法正常使用", Toast.LENGTH_LONG).show();
            }
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == REQUEST_OVERLAY_PERMISSION) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    Log.i(TAG, "悬浮窗权限已授予");
                } else {
                    Log.e(TAG, "悬浮窗权限被拒绝，无法显示停止按钮");
                    Toast.makeText(this, "悬浮窗权限被拒绝，无法显示停止按钮", Toast.LENGTH_LONG).show();
                }
            }
        }
    }
    
    /**
     * 检查更新
     */
    private void checkForUpdates() {
        Log.i(TAG, "检查应用更新");
        new CheckUpdateTask().execute();
    }
    
    /**
     * 检查更新的异步任务
     */
    private class CheckUpdateTask extends AsyncTask<Void, Void, String[]> {
        @Override
        protected String[] doInBackground(Void... params) {
            try {
                URL url = new URL(VERSION_CHECK_URL);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                
                int responseCode = conn.getResponseCode();
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                    String line;
                    StringBuilder response = new StringBuilder();
                    while ((line = reader.readLine()) != null) {
                        response.append(line);
                    }
                    reader.close();
                    
                    String jsonResponse = response.toString().trim();
                    Log.i(TAG, "=== Gitee API响应开始 ===");
                    Log.i(TAG, jsonResponse);
                    Log.i(TAG, "=== Gitee API响应结束 ===");
                    
                    // 解析JSON响应，提取版本号和下载URL
                    Log.i(TAG, "开始解析版本号和下载URL");
                    String latestVersion = parseVersionFromJson(jsonResponse);
                    String downloadUrl = parseDownloadUrlFromJson(jsonResponse);
                    Log.i(TAG, "解析结果 - 版本号: " + latestVersion + ", 下载URL: " + downloadUrl);
                    
                    if (latestVersion != null && downloadUrl != null) {
                        APK_DOWNLOAD_URL = downloadUrl;
                        return new String[]{latestVersion, downloadUrl};
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "检查更新失败: " + e.getMessage());
            }
            return null;
        }
        
        @Override
        protected void onPostExecute(String[] result) {
            if (result != null && result.length == 2) {
                String latestVersion = result[0];
                String downloadUrl = result[1];
                
                Log.i(TAG, "最新版本: " + latestVersion);
                Log.i(TAG, "下载URL: " + downloadUrl);
                
                String currentVersion = "1.0.8";
                if (isNewVersionAvailable(currentVersion, latestVersion)) {
                    Log.i(TAG, "发现新版本: " + latestVersion);
                    showUpdateDialog(latestVersion);
                } else {
                    Log.i(TAG, "当前已是最新版本");
                    Toast.makeText(MainActivity.this, "当前已是最新版本", Toast.LENGTH_SHORT).show();
                }
            } else {
                Log.w(TAG, "无法获取最新版本信息");
                Toast.makeText(MainActivity.this, "检查更新失败，请稍后重试", Toast.LENGTH_SHORT).show();
            }
        }
    }
    
    /**
     * 从JSON响应中解析版本号
     */
    private String parseVersionFromJson(String jsonResponse) {
        try {
            // 简单的JSON解析，提取tag_name字段
            int tagNameStart = jsonResponse.indexOf("\"tag_name\":");
            if (tagNameStart != -1) {
                int valueStart = jsonResponse.indexOf("\"", tagNameStart + 10);
                int valueEnd = jsonResponse.indexOf("\"", valueStart + 1);
                if (valueStart != -1 && valueEnd != -1) {
                    String version = jsonResponse.substring(valueStart + 1, valueEnd);
                    // 移除版本号前缀，如 "v1.0.7" -> "1.0.7"
                    if (version.startsWith("v")) {
                        version = version.substring(1);
                    }
                    Log.i(TAG, "解析到版本号: " + version);
                    return version;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "解析版本号失败: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * 从JSON响应中解析下载URL
     */
    private String parseDownloadUrlFromJson(String jsonResponse) {
        try {
            // 简单的JSON解析，提取assets中的browser_download_url
            int assetsStart = jsonResponse.indexOf("\"assets\":");
            if (assetsStart != -1) {
                int downloadUrlStart = jsonResponse.indexOf("\"browser_download_url\":", assetsStart);
                if (downloadUrlStart != -1) {
                    int valueStart = jsonResponse.indexOf("\"", downloadUrlStart + 22);
                    int valueEnd = jsonResponse.indexOf("\"", valueStart + 1);
                    if (valueStart != -1 && valueEnd != -1) {
                        return jsonResponse.substring(valueStart + 1, valueEnd);
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "解析下载URL失败: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * 检查是否有新版本可用
     */
    private boolean isNewVersionAvailable(String currentVersion, String latestVersion) {
        try {
            String[] currentParts = currentVersion.split("\\.");
            String[] latestParts = latestVersion.split("\\.");
            
            for (int i = 0; i < Math.max(currentParts.length, latestParts.length); i++) {
                int current = i < currentParts.length ? Integer.parseInt(currentParts[i]) : 0;
                int latest = i < latestParts.length ? Integer.parseInt(latestParts[i]) : 0;
                
                if (latest > current) {
                    return true;
                } else if (latest < current) {
                    return false;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "版本比较失败: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * 显示更新对话框
     */
    private void showUpdateDialog(final String latestVersion) {
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("发现新版本");
        builder.setMessage("当前版本: 1.0.8\n最新版本: " + latestVersion + "\n\n是否更新到最新版本？");
        builder.setPositiveButton("更新", new android.content.DialogInterface.OnClickListener() {
            @Override
            public void onClick(android.content.DialogInterface dialog, int which) {
                dialog.dismiss();
                downloadAndInstallApk();
            }
        });
        builder.setNegativeButton("取消", new android.content.DialogInterface.OnClickListener() {
            @Override
            public void onClick(android.content.DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        builder.setNeutralButton("不再提示", new android.content.DialogInterface.OnClickListener() {
            @Override
            public void onClick(android.content.DialogInterface dialog, int which) {
                updateNoRemind = true;
                saveConfig();
                dialog.dismiss();
                Toast.makeText(MainActivity.this, "已设置为不再提示更新", Toast.LENGTH_SHORT).show();
            }
        });
        builder.create().show();
    }
    
    /**
     * 下载并安装APK
     */
    private void downloadAndInstallApk() {
        Log.i(TAG, "开始下载APK");
        new DownloadApkTask().execute();
    }
    
    /**
     * 下载APK的异步任务
     */
    private class DownloadApkTask extends AsyncTask<Void, Integer, File> {
        private TextView updateStatusView;
        
        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            Toast.makeText(MainActivity.this, "开始下载新版本...", Toast.LENGTH_SHORT).show();
        }
        
        @Override
        protected File doInBackground(Void... params) {
            try {
                URL url = new URL(APK_DOWNLOAD_URL);
                URLConnection conn = url.openConnection();
                conn.connect();
                
                int fileLength = conn.getContentLength();
                InputStream input = conn.getInputStream();
                
                // 使用应用的外部私有存储目录，与log文件在同一位置
                File downloadDir = new File(getExternalFilesDir(null), "download");
                if (!downloadDir.exists()) {
                    downloadDir.mkdirs();
                }
                File apkFile = new File(downloadDir, "CarKaraoke.apk");
                FileOutputStream output = new FileOutputStream(apkFile);
                
                byte[] buffer = new byte[1024];
                int bytesRead;
                int totalRead = 0;
                
                while ((bytesRead = input.read(buffer)) != -1) {
                    output.write(buffer, 0, bytesRead);
                    totalRead += bytesRead;
                    int progress = (int) ((totalRead * 100) / fileLength);
                    publishProgress(progress);
                }
                
                output.flush();
                output.close();
                input.close();
                
                return apkFile;
            } catch (Exception e) {
                Log.e(TAG, "下载APK失败: " + e.getMessage());
                return null;
            }
        }
        
        @Override
        protected void onProgressUpdate(Integer... values) {
            super.onProgressUpdate(values);
            Log.i(TAG, "下载进度: " + values[0] + "%");
        }
        
        @Override
        protected void onPostExecute(File apkFile) {
            if (apkFile != null && apkFile.exists()) {
                Log.i(TAG, "APK下载完成: " + apkFile.getAbsolutePath());
                // 显示下载完成提示对话框
                showDownloadCompleteDialog(apkFile.getAbsolutePath());
            } else {
                Log.e(TAG, "APK下载失败");
                Toast.makeText(MainActivity.this, "APK下载失败", Toast.LENGTH_SHORT).show();
            }
        }
    }
    
    /**
     * 安装APK
     */
    private void installApk(File apkFile) {
        Log.i(TAG, "开始安装APK");
        Log.i(TAG, "APK文件路径: " + apkFile.getAbsolutePath());
        Log.i(TAG, "APK文件存在: " + apkFile.exists());
        Log.i(TAG, "APK文件大小: " + apkFile.length() + " 字节");
        
        // 标记正在安装，防止重复触发
        isInstalling = true;
        
        Log.i(TAG, "=== 开始安装流程 ===");
        Log.i(TAG, "当前应用版本: 1.0.6");
        Log.i(TAG, "尝试安装的APK: " + apkFile.getName());
        
        // 方法1：尝试使用系统的PackageInstaller API
        try {
            Log.i(TAG, "尝试使用PackageInstaller API安装APK");
            android.content.pm.PackageInstaller packageInstaller = getPackageManager().getPackageInstaller();
            android.content.pm.PackageInstaller.SessionParams params = new android.content.pm.PackageInstaller.SessionParams(
                android.content.pm.PackageInstaller.SessionParams.MODE_FULL_INSTALL
            );
            params.setAppPackageName("com.car.karake");
            
            int sessionId = packageInstaller.createSession(params);
            Log.i(TAG, "创建安装会话成功，sessionId: " + sessionId);
            
            android.content.pm.PackageInstaller.Session session = packageInstaller.openSession(sessionId);
            Log.i(TAG, "打开安装会话成功");
            
            // 将APK文件写入会话
            OutputStream outputStream = session.openWrite("package", 0, apkFile.length());
            Log.i(TAG, "打开输出流成功");
            
            FileInputStream fis = new FileInputStream(apkFile);
            byte[] buffer = new byte[65536];
            int bytesRead;
            long totalWritten = 0;
            
            while ((bytesRead = fis.read(buffer)) != -1) {
                outputStream.write(buffer, 0, bytesRead);
                totalWritten += bytesRead;
                Log.i(TAG, "写入APK数据: " + totalWritten + " / " + apkFile.length() + " 字节");
            }
            
            fis.close();
            outputStream.flush();
            outputStream.close();
            Log.i(TAG, "APK文件写入完成");
            
            // 提交会话
            session.commit(createIntentSender(sessionId));
            Log.i(TAG, "PackageInstaller安装请求提交成功");
            Toast.makeText(this, "正在安装更新...", Toast.LENGTH_LONG).show();
            
            // 延迟一段时间后检查安装状态
            new android.os.Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    checkInstallationStatus();
                }
            }, 10000);
            
        } catch (Exception e) {
            Log.e(TAG, "PackageInstaller安装失败: " + e.getMessage(), e);
            Toast.makeText(this, "安装失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            
            // 不再尝试自动安装，让用户使用应用管家手动安装
            Log.i(TAG, "安装流程已简化，用户需使用应用管家手动安装");
            Toast.makeText(this, "请使用应用管家安装更新", Toast.LENGTH_SHORT).show();
            Toast.makeText(this, "APK文件路径: " + apkFile.getAbsolutePath(), Toast.LENGTH_LONG).show();
            isInstalling = false;
        }
    }
    
    /**
     * 检查安装状态
     */
    private void checkInstallationStatus() {
        try {
            android.content.pm.PackageInfo packageInfo = getPackageManager().getPackageInfo(
                "com.car.karake", 0
            );
            String installedVersion = packageInfo.versionName;
            int versionCode = packageInfo.versionCode;
            String currentVersion = "1.0.8";
            Log.i(TAG, "当前安装版本: " + installedVersion + " (code: " + versionCode + ")");
            Log.i(TAG, "更新前版本: " + currentVersion);
            
            if (isNewVersionAvailable(currentVersion, installedVersion)) {
                Log.i(TAG, "安装成功，版本已更新到: " + installedVersion);
                Toast.makeText(this, "安装成功，版本已更新到: " + installedVersion, Toast.LENGTH_SHORT).show();
                // 安装成功后不自动重启应用，让用户手动打开
                Log.i(TAG, "安装成功，应用已更新，请手动打开新版本");
            } else {
                Log.w(TAG, "安装可能失败，当前版本仍为: " + installedVersion);
                Toast.makeText(this, "安装可能失败，当前版本仍为: " + installedVersion, Toast.LENGTH_SHORT).show();
            }
        } catch (Exception e) {
            Log.e(TAG, "检查安装状态失败: " + e.getMessage());
        } finally {
            isInstalling = false;
        }
    }
    
    /**
     * 重启应用
     */
    private void restartApp() {
        Log.i(TAG, "重启应用");
        try {
            // 强制停止当前应用
            android.content.Intent restartIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
            restartIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
            
            // 延迟启动，确保当前进程已退出
            new android.os.Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    startActivity(restartIntent);
                    // 退出当前进程
                    finish();
                    System.exit(0);
                }
            }, 1000);
        } catch (Exception e) {
            Log.e(TAG, "重启应用失败: " + e.getMessage());
        }
    }
    
    /**
     * 创建安装完成的IntentSender
     */
    private android.content.IntentSender createIntentSender(int sessionId) {
        Intent intent = new Intent(this, MainActivity.class);
        intent.setAction("INSTALL_COMPLETE");
        intent.putExtra("SESSION_ID", sessionId);
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            sessionId, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT
        );
        return pendingIntent.getIntentSender();
    }
    
    /**
     * 显示下载完成提示对话框
     */
    private void showDownloadCompleteDialog(String apkFilePath) {
        Log.i(TAG, "显示下载完成提示对话框");
        
        // 获取系统主题模式，保持对话框与系统主题一致
        int currentNightMode = getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkMode = currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        
        // 构建提示信息
        String message = "已下载至" + apkFilePath + "\n\n请使用\"应用管家\"安装更新！\n\n不会更新请看小红书邪恶银渐层更新教程更新！";
        
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("下载完成");
        builder.setMessage(message);
        
        builder.setPositiveButton("确定", new android.content.DialogInterface.OnClickListener() {
            @Override
            public void onClick(android.content.DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        
        builder.create().show();
        Log.i(TAG, "下载完成提示对话框显示完成");
    }
    
    // 辅助方法：创建自定义卡片按钮
    private Button createCustomCard(String text, int buttonColor, int textColor, int cardColor, boolean isDarkMode) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextSize(20);
        button.setTextColor(textColor);
        button.setTypeface(null, Typeface.BOLD);
        button.setGravity(android.view.Gravity.CENTER);
        button.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1
        ));
        button.setPadding(24, 24, 24, 24);
        button.setAllCaps(false);
        
        // 创建卡片背景
        android.graphics.drawable.GradientDrawable buttonBg = new android.graphics.drawable.GradientDrawable();
        buttonBg.setColor(buttonColor);
        buttonBg.setCornerRadius(16);
        buttonBg.setStroke(2, isDarkMode ? Color.parseColor("#333333") : Color.parseColor("#E0E0E0"));
        button.setBackground(buttonBg);
        
        // 添加点击效果
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // 点击缩放反馈
                v.animate().scaleX(0.97f).scaleY(0.97f).setDuration(150).withEndAction(new Runnable() {
                    @Override
                    public void run() {
                        v.animate().scaleX(1.0f).scaleY(1.0f).setDuration(150).start();
                    }
                }).start();
            }
        });
        
        return button;
    }
    
    // 辅助方法：创建状态卡片
    private android.widget.LinearLayout createStatusCard(String status, int statusColor, int textColor, int cardColor, boolean isDarkMode) {
        android.widget.LinearLayout card = new android.widget.LinearLayout(this);
        card.setOrientation(android.widget.LinearLayout.VERTICAL);
        card.setGravity(android.view.Gravity.CENTER);
        card.setPadding(32, 32, 32, 32);
        card.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1
        ));
        
        // 创建卡片背景
        android.graphics.drawable.GradientDrawable cardBg = new android.graphics.drawable.GradientDrawable();
        cardBg.setColor(statusColor);
        cardBg.setCornerRadius(16);
        cardBg.setStroke(2, isDarkMode ? Color.parseColor("#333333") : Color.parseColor("#E0E0E0"));
        card.setBackground(cardBg);
        
        // 状态标题
        TextView statusTitle = new TextView(this);
        statusTitle.setText("K歌状态");
        statusTitle.setTextSize(18);
        statusTitle.setTextColor(textColor);
        statusTitle.setTypeface(null, Typeface.BOLD);
        statusTitle.setPadding(0, 0, 0, 16);
        statusTitle.setGravity(android.view.Gravity.CENTER);
        
        // 状态内容
        statusView = new TextView(this);
        statusView.setText(status);
        statusView.setTextSize(24);
        statusView.setTextColor(textColor);
        statusView.setTypeface(null, Typeface.BOLD);
        statusView.setGravity(android.view.Gravity.CENTER);
        
        card.addView(statusTitle);
        card.addView(statusView);
        
        return card;
    }
    
    // 更新状态卡片颜色和文本
    private void updateStatusCard(boolean isDarkMode, boolean isKaraokeActive) {
        String status = isKaraokeActive ? "K歌中" : "等待开始K歌";
        int statusColor = isKaraokeActive ? Color.parseColor("#34DBA1") : Color.parseColor("#C4BBF3");
        int textColor = isDarkMode ? Color.parseColor("#FFFFFF") : Color.parseColor("#000000");
        
        statusView.setText(status);
        
        // 更新卡片背景颜色
        android.graphics.drawable.GradientDrawable cardBg = (android.graphics.drawable.GradientDrawable) statusCard.getBackground();
        cardBg.setColor(statusColor);
    }
    
    // 辅助方法：创建控制卡片
    private android.widget.LinearLayout createControlCard(String label, int cardColor, int textColor, boolean isDarkMode) {
        android.widget.LinearLayout card = new android.widget.LinearLayout(this);
        card.setOrientation(android.widget.LinearLayout.VERTICAL);
        card.setPadding(32, 32, 32, 32);
        card.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1
        ));
        
        // 创建卡片背景
        android.graphics.drawable.GradientDrawable cardBg = new android.graphics.drawable.GradientDrawable();
        cardBg.setColor(cardColor);
        cardBg.setCornerRadius(16);
        cardBg.setStroke(2, isDarkMode ? Color.parseColor("#333333") : Color.parseColor("#E0E0E0"));
        card.setBackground(cardBg);
        
        return card;
    }
    
    // 辅助方法：创建配置卡片（带开关）
    private android.widget.LinearLayout createConfigCard(String label, boolean checked, int switchColor, int textColor, int cardColor, boolean isDarkMode) {
        android.widget.LinearLayout card = new android.widget.LinearLayout(this);
        card.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        card.setGravity(android.view.Gravity.CENTER_VERTICAL);
        card.setPadding(32, 32, 32, 32);
        card.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1
        ));
        
        // 创建卡片背景
        android.graphics.drawable.GradientDrawable cardBg = new android.graphics.drawable.GradientDrawable();
        cardBg.setColor(cardColor);
        cardBg.setCornerRadius(16);
        cardBg.setStroke(2, isDarkMode ? Color.parseColor("#333333") : Color.parseColor("#E0E0E0"));
        card.setBackground(cardBg);
        
        // 配置标签
        TextView configLabel = new TextView(this);
        configLabel.setText(label);
        configLabel.setTextSize(20);
        configLabel.setTextColor(textColor);
        configLabel.setTypeface(null, Typeface.BOLD);
        configLabel.setGravity(android.view.Gravity.CENTER);
        configLabel.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
            1
        ));
        
        // 配置开关
        android.widget.Switch configSwitch = new android.widget.Switch(this);
        configSwitch.setChecked(checked);
        
        // 自定义开关颜色：勾选为绿色#34DBA1，不勾选为紫色#C4BBF3
        int trackColor = checked ? Color.parseColor("#34DBA1") : Color.parseColor("#C4BBF3");
        int thumbColor = checked ? Color.parseColor("#34DBA1") : Color.parseColor("#C4BBF3");
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            configSwitch.setTrackTintList(android.content.res.ColorStateList.valueOf(trackColor));
            configSwitch.setThumbTintList(android.content.res.ColorStateList.valueOf(thumbColor));
        }
        
        card.addView(configLabel);
        card.addView(configSwitch);
        
        return card;
    }
    
    // 辅助方法：创建自定义滑块
    private android.widget.SeekBar createCustomSeekBar(android.content.Context context, boolean isDarkMode) {
        android.widget.SeekBar seekBar = new android.widget.SeekBar(context);
        seekBar.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            48
        ));
        
        // 自定义滑块样式
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // 设置进度条颜色
            int thumbColor = Color.parseColor("#00C8FF");
            
            // 设置进度相关颜色
            seekBar.setThumbTintList(android.content.res.ColorStateList.valueOf(thumbColor));
            seekBar.setProgressTintList(android.content.res.ColorStateList.valueOf(thumbColor));
            seekBar.setSecondaryProgressTintList(android.content.res.ColorStateList.valueOf(thumbColor));
        }
        
        return seekBar;
    }
    
    // 辅助方法：创建垂直间距
    private android.view.View createVerticalSpacer(int height) {
        android.view.View spacer = new android.view.View(this);
        spacer.setLayoutParams(new android.widget.LinearLayout.LayoutParams(
            android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
            height
        ));
        return spacer;
    }
    
    // 显示日志对话框
    private void showLogDialog() {
        // 创建日志内容
        StringBuilder logContent = new StringBuilder();
        logContent.append("=== 无麦K歌应用日志 ===\n\n");
        
        // 添加当前状态信息
        logContent.append("当前状态：\n");
        logContent.append("- 录音状态: " + (isRecording ? "正在录音" : "未录音") + "\n");
        logContent.append("- 自动开始K歌: " + autoStartKaraoke + "\n");
        logContent.append("- 更新不再提示: " + updateNoRemind + "\n\n");
        logContent.append("音频设置：\n");
        logContent.append("- 延迟时间: " + delayTime + "ms\n");
        logContent.append("- 回声强度: " + (int)(echoLevel * 100) + "%\n");
        logContent.append("- 增幅倍数: " + gainLevel + "倍\n");
        logContent.append("- 当前声道: " + channelNames[currentChannelIndex] + "\n");
        logContent.append("- 输出声道: 单声道\n\n");
        logContent.append("系统信息：\n");
        logContent.append("- Android版本: " + Build.VERSION.RELEASE + "\n");
        logContent.append("- 应用版本: 1.0.8\n\n");
        
        // 添加收集的日志条目
        logContent.append("运行日志：\n");
        if (logs.length() == 0) {
            logContent.append("(暂无日志)");
        } else {
            logContent.append(logs.toString());
        }
        
        // 创建对话框
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        builder.setTitle("应用日志");
        
        // 创建滚动文本视图
        android.widget.ScrollView scrollView = new android.widget.ScrollView(this);
        TextView logTextView = new TextView(this);
        logTextView.setText(logContent.toString());
        logTextView.setTextSize(12);
        logTextView.setPadding(16, 16, 16, 16);
        logTextView.setTextColor(Color.parseColor("#000000"));
        logTextView.setTypeface(Typeface.MONOSPACE); // 使用等宽字体，提高日志可读性
        
        scrollView.addView(logTextView);
        builder.setView(scrollView);
        
        builder.setPositiveButton("确定", new android.content.DialogInterface.OnClickListener() {
            @Override
            public void onClick(android.content.DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        
        builder.create().show();
    }
}
EOF

# 步骤3：创建FloatingWindowService类
cat > "${PROJECT_DIR}/temp_build/com/car/karake/FloatingWindowService.java" << 'EOF'
package com.car.karake;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.Toast;
import android.os.Build;
import android.graphics.PixelFormat;
import android.util.Log;
import android.widget.RelativeLayout;
import android.graphics.Color;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.RoundRectShape;
import android.content.res.Configuration;

public class FloatingWindowService extends Service {

    private static final String TAG = "CarKaraoke";    
    private WindowManager windowManager;
    private View floatingView;
    private WindowManager.LayoutParams params;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "创建悬浮窗服务");

        // 动态创建悬浮窗视图
        RelativeLayout floatingLayout = new RelativeLayout(this);
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.MATCH_PARENT
        );
        floatingLayout.setLayoutParams(layoutParams);
        
        // 设置悬浮窗背景为半透明白色
        floatingLayout.setBackgroundColor(Color.argb(128, 255, 255, 255)); // 半透明白色
        
        // 设置圆角背景
        floatingLayout.setPadding(8, 8, 8, 8);
        floatingLayout.setBackgroundDrawable(getDrawableWithRoundedCorners(80, 120));
        
        // 创建停止按钮
        ImageView btnStopKaraoke = new ImageView(this);
        RelativeLayout.LayoutParams btnParams = new RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.MATCH_PARENT
        );
        btnParams.addRule(RelativeLayout.CENTER_IN_PARENT);
        btnStopKaraoke.setLayoutParams(btnParams);
        
        // 根据日夜模式使用不同的图片
        int nightMode = getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkMode = nightMode == Configuration.UI_MODE_NIGHT_YES;
        
        if (isDarkMode) {
            // 夜晚模式使用maikefeng_2.png
            int resId = getResources().getIdentifier("maikefeng_2", "drawable", getPackageName());
            if (resId > 0) {
                btnStopKaraoke.setImageResource(resId);
            } else {
                // 如果资源不存在，使用系统默认图标
                btnStopKaraoke.setImageResource(android.R.drawable.ic_media_pause);
            }
        } else {
            // 白天模式使用maikefeng.png
            int resId = getResources().getIdentifier("maikefeng", "drawable", getPackageName());
            if (resId > 0) {
                btnStopKaraoke.setImageResource(resId);
            } else {
                // 如果资源不存在，使用系统默认图标
                btnStopKaraoke.setImageResource(android.R.drawable.ic_media_pause);
            }
        }
        
        btnStopKaraoke.setScaleType(ImageView.ScaleType.FIT_CENTER); // 修改为FIT_CENTER，确保图片按比例缩放以适应悬浮窗大小
        btnStopKaraoke.setBackgroundColor(Color.TRANSPARENT);
        
        // 设置停止按钮点击事件
        btnStopKaraoke.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "悬浮窗停止按钮被点击");
                
                // 发送广播通知MainActivity停止K歌，而不打开APP
                Intent stopIntent = new Intent("com.car.karake.STOP_KARAOKE");
                sendBroadcast(stopIntent);
                
                // 显示无麦K歌已关闭的提示
                Toast.makeText(getApplicationContext(), "无麦K歌已关闭", Toast.LENGTH_SHORT).show();
                
                // 停止悬浮窗服务
                stopSelf();
                Log.i(TAG, "悬浮窗服务已停止");
            }
        });
        
        // 添加按钮到布局
        floatingLayout.addView(btnStopKaraoke);
        
        // 设置为悬浮窗视图
        floatingView = floatingLayout;

        // 设置悬浮窗参数
        int layoutFlag;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            layoutFlag = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            layoutFlag = WindowManager.LayoutParams.TYPE_PHONE;
        }

        params = new WindowManager.LayoutParams(
            80, // 宽度（像素）
            80, // 高度（像素），与宽度相同以形成圆形
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        );

        // 设置悬浮窗位置（屏幕右侧中间）
        params.gravity = android.view.Gravity.END | android.view.Gravity.CENTER;
        params.x = 0;
        params.y = 0;

        // 获取WindowManager服务
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        // 添加悬浮窗到WindowManager
        try {
            windowManager.addView(floatingView, params);
            Log.i(TAG, "悬浮窗已添加到WindowManager");
        } catch (Exception e) {
            Log.e(TAG, "添加悬浮窗失败: " + e.getMessage());
            Toast.makeText(this, "添加悬浮窗失败: " + e.getMessage(), Toast.LENGTH_LONG).show();
            stopSelf();
        }

        // 设置悬浮窗拖拽功能
        floatingView.setOnTouchListener(new FloatingTouchListener());
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // 移除悬浮窗
        if (floatingView != null && windowManager != null) {
            try {
                windowManager.removeView(floatingView);
                Log.i(TAG, "悬浮窗已从WindowManager移除");
            } catch (Exception e) {
                Log.e(TAG, "移除悬浮窗失败: " + e.getMessage());
            }
        }
    }

    // 悬浮窗拖拽监听
    private class FloatingTouchListener implements View.OnTouchListener {
        private int initialX;
        private int initialY;
        private float initialTouchX;
        private float initialTouchY;

        @Override
        public boolean onTouch(View v, android.view.MotionEvent event) {
            switch (event.getAction()) {
                case android.view.MotionEvent.ACTION_DOWN:
                    // 记录初始位置
                    initialX = params.x;
                    initialY = params.y;
                    initialTouchX = event.getRawX();
                    initialTouchY = event.getRawY();
                    return true;
                case android.view.MotionEvent.ACTION_MOVE:
                    // 计算新位置
                    params.x = initialX + (int) (event.getRawX() - initialTouchX);
                    params.y = initialY + (int) (event.getRawY() - initialTouchY);
                    
                    // 更新悬浮窗位置
                    windowManager.updateViewLayout(floatingView, params);
                    return true;
                default:
                    return false;
            }
        }
    }
    
    // 创建圆角背景的方法
    private ShapeDrawable getDrawableWithRoundedCorners(float width, float height) {
        float[] outerR = new float[8];
        // 计算圆形半径，取宽高的最小值的一半
        float radius = Math.min(width, height) / 2;
        
        // 设置8个角的半径（都为圆形半径，形成圆形）
        for (int i = 0; i < 8; i++) {
            outerR[i] = radius;
        }
        
        RoundRectShape shape = new RoundRectShape(outerR, null, null);
        ShapeDrawable drawable = new ShapeDrawable(shape);
        drawable.getPaint().setColor(Color.argb(128, 255, 255, 255)); // 半透明白色
        return drawable;
    }
}
EOF

# 步骤3：编译Java类
javac -d "${PROJECT_DIR}/temp_build" -cp "${PLATFORM}/android.jar:${PROJECT_DIR}/app/libs/*" "${PROJECT_DIR}/temp_build/com/car/karake/MainActivity.java" "${PROJECT_DIR}/temp_build/com/car/karake/FloatingWindowService.java"

# 列出编译生成的class文件
echo "=== 编译生成的class文件 ==="
ls -la "${PROJECT_DIR}/temp_build/com/car/karake/"

# 步骤4：生成dex文件（包含所有class文件）
# 找到所有class文件
CLASS_FILES="$(find "${PROJECT_DIR}/temp_build/com/car/karake/" -name "*.class")"
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

# 步骤6：复制必要的资源目录到temp_build
mkdir -p "${PROJECT_DIR}/temp_build/res"
cp -r "${PROJECT_DIR}/app/src/main/res/layout" "${PROJECT_DIR}/temp_build/res/" 2>/dev/null || echo "layout目录不存在，跳过"

# 创建drawable目录
mkdir -p "${PROJECT_DIR}/temp_build/res/drawable"

# 复制其他drawable资源（如果有）
copied=$(cp -r "${PROJECT_DIR}/app/src/main/res/drawable"/* "${PROJECT_DIR}/temp_build/res/drawable/" 2>/dev/null || echo "其他drawable资源不存在，跳过")
if [[ "$copied" != "其他drawable资源不存在，跳过" ]]; then
    echo "已复制其他drawable资源"
fi

# 复制悬浮窗所需的图片资源
if [ -f "${PROJECT_DIR}/maikefeng.png" ]; then
    cp "${PROJECT_DIR}/maikefeng.png" "${PROJECT_DIR}/temp_build/res/drawable/"
    echo "已复制maikefeng.png到drawable目录"
else
    echo "警告：maikefeng.png文件不存在"
fi

if [ -f "${PROJECT_DIR}/maikefeng-2.png" ]; then
    # 将文件名中的连字符替换为下划线，符合Android资源文件命名规则
    cp "${PROJECT_DIR}/maikefeng-2.png" "${PROJECT_DIR}/temp_build/res/drawable/maikefeng_2.png"
    echo "已复制maikefeng-2.png到drawable目录（重命名为maikefeng_2.png）"
else
    echo "警告：maikefeng-2.png文件不存在"
fi

# 复制自适应图标资源
mkdir -p "${PROJECT_DIR}/temp_build/res"

# 复制mipmap-anydpi-v26目录（自适应图标配置）
cp -r "${PROJECT_DIR}/icon/res/mipmap-anydpi-v26" "${PROJECT_DIR}/temp_build/res/" 2>/dev/null || echo "自适应图标配置目录不存在，跳过"

# 复制所有分辨率的图标资源
cp -r "${PROJECT_DIR}/icon/res/mipmap-"* "${PROJECT_DIR}/temp_build/res/" 2>/dev/null || echo "图标资源目录不存在，跳过"

# 复制自适应图标所需的drawable资源
cp -r "${PROJECT_DIR}/icon/res/drawable/ic_launcher_background.xml" "${PROJECT_DIR}/temp_build/res/drawable/" 2>/dev/null || echo "图标背景资源不存在，跳过"
cp -r "${PROJECT_DIR}/icon/res/drawable/ic_launcher_foreground.xml" "${PROJECT_DIR}/temp_build/res/drawable/" 2>/dev/null || echo "图标前景资源不存在，跳过"
mkdir -p "${PROJECT_DIR}/temp_build/res/values"
echo '<resources><string name="app_name">无麦K歌</string></resources>' > "${PROJECT_DIR}/temp_build/res/values/strings.xml"

# 步骤7：使用aapt创建APK（明确指定资源目录，并输出详细日志）
echo "正在使用aapt创建APK..."
"${BUILD_TOOLS}/aapt" package -f -v -M "${PROJECT_DIR}/temp_build/AndroidManifest.xml" -I "${PLATFORM}/android.jar" -S "${PROJECT_DIR}/temp_build/res" -F "${PROJECT_DIR}/temp_build/app-unsigned.apk"

# 检查aapt是否成功生成APK
if [ ! -f "${PROJECT_DIR}/temp_build/app-unsigned.apk" ]; then
    echo "错误：aapt未能生成APK文件！"
    exit 1
fi

# 查看aapt生成的APK内容
echo "aapt生成的APK内容："
unzip -l "${PROJECT_DIR}/temp_build/app-unsigned.apk"

# 步骤8：添加classes.dex到APK
zip -j "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build/classes.dex"

# 步骤9：对齐APK文件
echo "正在对齐APK文件..."
"${BUILD_TOOLS}/zipalign" -f 4 "${PROJECT_DIR}/temp_build/app-unsigned.apk" "${PROJECT_DIR}/temp_build/app-aligned.apk"

# 步骤10：签名APK
KEYSTORE_FILE="${PROJECT_DIR}/carkarake.keystore"
if [ ! -f "${KEYSTORE_FILE}" ]; then
    echo "正在生成carkarake密钥库..."
    keytool -genkey -v -keystore "${KEYSTORE_FILE}" \
        -storepass vip12345 -keypass vip12345 \
        -alias carkarake -dname "CN=Elliot,O=CarKaraoke,C=CN" \
        -keyalg RSA -keysize 2048 -validity 10000
fi

echo "正在签名APK..."
"${BUILD_TOOLS}/apksigner" sign --ks "${KEYSTORE_FILE}" \
    --ks-pass pass:vip12345 \
    --key-pass pass:vip12345 \
    --min-sdk-version 29 \
    --out "${PROJECT_DIR}/${APK_NAME}" \
    "${PROJECT_DIR}/temp_build/app-aligned.apk"

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
