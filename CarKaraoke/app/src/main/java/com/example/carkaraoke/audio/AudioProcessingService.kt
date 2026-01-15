package com.example.carkaraoke.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class AudioProcessingService : Service() {

    private val TAG = "AudioProcessingService"
    private val CHANNEL_ID = "CarKaraokeServiceChannel"
    private val NOTIFICATION_ID = 1

    // Audio parameters with device compatibility
    private val SAMPLE_RATE = 48000
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private var channelCount = 8 // Default to 8-channel VR microphone array
    private var inputChannelConfig = AudioFormat.CHANNEL_IN_8CHANNEL
    private lateinit var BUFFER_SIZE: Int
    
    // Audio gain settings - adjust this value to increase/decrease volume
    private val AUDIO_GAIN = 6.0f // 6x gain, increased for better volume

    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var isRecording = false
    private var audioThread: Thread? = null
    private var isServiceRunning = false

    // Native audio processing
    private external fun initAudioProcessing(sampleRate: Int, channels: Int)
    private external fun processAudio(input: ShortArray, output: ShortArray, size: Int)
    private external fun releaseAudioProcessing()

    companion object {
        init {
            try {
                System.loadLibrary("car_karaoke_audio")
                Log.d("AudioProcessingService", "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e("AudioProcessingService", "Failed to load native library: ${e.message}")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        isServiceRunning = true
        
        // Check device compatibility and configure audio parameters
        configureAudioParameters()
        
        try {
            initAudioProcessing(SAMPLE_RATE, channelCount)
            Log.d(TAG, "Native audio processing initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize native audio processing: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRecording) {
            startAudioProcessing()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        stopAudioProcessing()
        try {
            releaseAudioProcessing()
            Log.d(TAG, "Native audio processing released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release native audio processing: ${e.message}")
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Car Karaoke Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("车机版无麦K歌")
            .setContentText("正在运行中...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }
    
    private fun configureAudioParameters() {
        // Try different channel configurations based on device support
        val supportedChannelConfigs = listOf(
            AudioFormat.CHANNEL_IN_8CHANNEL,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.CHANNEL_IN_MONO
        )
        
        val supportedChannelCounts = listOf(8, 2, 1)
        
        for (i in supportedChannelConfigs.indices) {
            try {
                val bufferSize = AudioRecord.getMinBufferSize(
                    SAMPLE_RATE, 
                    supportedChannelConfigs[i], 
                    AUDIO_FORMAT
                )
                
                if (bufferSize > 0) {
                    // This channel config is supported
                    inputChannelConfig = supportedChannelConfigs[i]
                    channelCount = supportedChannelCounts[i]
                    BUFFER_SIZE = bufferSize * 2
                    Log.d(TAG, "Using ${channelCount}-channel configuration")
                    return
                }
            } catch (e: IllegalArgumentException) {
                // Channel config not supported, try next one
                Log.d(TAG, "Channel config ${supportedChannelConfigs[i]} not supported: ${e.message}")
            }
        }
        
        // Fallback to mono if nothing else works
        inputChannelConfig = AudioFormat.CHANNEL_IN_MONO
        channelCount = 1
        BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, inputChannelConfig, AUDIO_FORMAT) * 2
        Log.d(TAG, "Fallback to 1-channel configuration")
    }
    
    private fun checkMicrophonePermission(): Boolean {
        val permission = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.RECORD_AUDIO
        )
        val result = permission == PackageManager.PERMISSION_GRANTED
        Log.d(TAG, "Microphone permission: $result")
        return result
    }

    private fun startAudioProcessing() {
        if (isRecording || !isServiceRunning) return
        
        // Check microphone permission before starting
        if (!checkMicrophonePermission()) {
            Log.e(TAG, "Microphone permission not granted")
            stopSelf()
            return
        }

        try {
            // Initialize AudioRecord with compatible channel config
            val audioSource = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                MediaRecorder.AudioSource.VOICE_RECOGNITION
            } else {
                MediaRecorder.AudioSource.MIC
            }
            
            // Check AudioRecord initialization before using
            val audioRecordTest = AudioRecord(
                audioSource,
                SAMPLE_RATE,
                inputChannelConfig,
                AUDIO_FORMAT,
                BUFFER_SIZE
            )
            
            if (audioRecordTest.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed, state: ${audioRecordTest.state}")
                audioRecordTest.release()
                stopSelf()
                return
            }
            
            audioRecord = audioRecordTest
            Log.d(TAG, "AudioRecord initialized successfully")

            // Initialize AudioTrack for playback - use separate audio session to avoid channel conflicts
            val trackBufferSize = AudioTrack.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_STEREO,
                AUDIO_FORMAT
            )
            
            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setFlags(android.media.AudioAttributes.FLAG_LOW_LATENCY)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setEncoding(AUDIO_FORMAT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                        .build()
                )
                .setBufferSizeInBytes(trackBufferSize)
                .setSessionId(AudioTrack.generateAudioSessionId())  // Use unique audio session to avoid channel conflicts
                .build()
            
            Log.d(TAG, "AudioTrack initialized successfully")

            isRecording = true
            audioThread = Thread { processAudioStream() }
            audioThread?.start()

            Log.d(TAG, "Audio processing started with ${channelCount}-channel configuration")
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception when accessing microphone: ${e.message}")
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start audio processing: ${e.message}")
            stopSelf()
        }
    }

    private fun stopAudioProcessing() {
        isRecording = false
        
        try {
            audioThread?.interrupt()
            audioThread?.join(1000) // Wait for thread to finish with timeout
        } catch (e: InterruptedException) {
            Log.e(TAG, "Interrupted while stopping audio thread: ${e.message}")
        }
        
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioTrack?.stop()
            audioTrack?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing audio resources: ${e.message}")
        } finally {
            audioRecord = null
            audioTrack = null
            audioThread = null
        }

        Log.d(TAG, "Audio processing stopped")
    }
    
    /**
     * Apply gain to audio samples to increase volume
     * @param buffer Audio buffer containing 16-bit PCM samples
     * @param size Number of samples to process
     */
    private fun applyGain(buffer: ShortArray, size: Int) {
        for (i in 0 until size) {
            // Convert to float for gain application
            var sample = buffer[i].toFloat()
            
            // Apply gain
            sample *= AUDIO_GAIN
            
            // Clamp to 16-bit PCM range to prevent clipping
            sample = sample.coerceIn(-32768.0f, 32767.0f)
            
            // Convert back to short
            buffer[i] = sample.toShort()
        }
        Log.d(TAG, "Applied ${AUDIO_GAIN}x gain to ${size} samples")
    }

    private fun processAudioStream() {
        val inputBuffer = ShortArray(BUFFER_SIZE / 2) // 16-bit PCM
        val outputBuffer = ShortArray(BUFFER_SIZE / 8) // Convert to stereo

        try {
            if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                audioRecord?.startRecording()
                Log.d(TAG, "AudioRecord started recording")
            } else {
                Log.e(TAG, "AudioRecord not initialized, cannot start recording")
                return
            }
            
            if (audioTrack?.state == AudioTrack.STATE_INITIALIZED) {
                audioTrack?.play()
                Log.d(TAG, "AudioTrack started playing")
            } else {
                Log.e(TAG, "AudioTrack not initialized, cannot start playing")
                return
            }

            while (isRecording && !Thread.currentThread().isInterrupted) {
                try {
                    // Read audio from microphone array
                    val readSize = audioRecord?.read(inputBuffer, 0, inputBuffer.size) ?: 0
                    if (readSize > 0) {
                        // Process audio using native code (if available)
                        try {
                            processAudio(inputBuffer, outputBuffer, readSize)
                        } catch (e: Exception) {
                            Log.e(TAG, "Native audio processing error: ${e.message}")
                            // Fallback: copy input to output directly
                            System.arraycopy(inputBuffer, 0, outputBuffer, 0, outputBuffer.size)
                        }

                        // Apply audio gain to increase volume
                        applyGain(outputBuffer, readSize / (channelCount / 2))

                        // Play processed audio
                        audioTrack?.write(outputBuffer, 0, readSize / (channelCount / 2))
                    } else if (readSize == AudioRecord.ERROR || readSize == AudioRecord.ERROR_INVALID_OPERATION) {
                        Log.e(TAG, "AudioRecord error: $readSize")
                        break
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing audio: ${e.message}")
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Critical error in audio processing thread: ${e.message}")
        } finally {
            try {
                audioRecord?.stop()
                audioTrack?.stop()
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping audio components: ${e.message}")
            }
        }
    }
}
