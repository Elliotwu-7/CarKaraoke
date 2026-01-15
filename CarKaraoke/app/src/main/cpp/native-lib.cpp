#include <jni.h>
#include <string>
#include <android/log.h>
#include "audio_processor.h"

#define TAG "CarKaraokeNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Global audio processor instance
static AudioProcessor* audioProcessor = nullptr;

extern "C" JNIEXPORT void JNICALL
Java_com_example_carkaraoke_audio_AudioProcessingService_initAudioProcessing(
        JNIEnv* env,
        jobject /* this */,
        jint sample_rate,
        jint channels) {
    try {
        if (audioProcessor == nullptr) {
            audioProcessor = new AudioProcessor(sample_rate, channels);
            LOGD("Initialized audio processing with sample rate: %d, channels: %d", sample_rate, channels);
        }
    } catch (const std::exception& e) {
        LOGE("Failed to initialize audio processing: %s", e.what());
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_carkaraoke_audio_AudioProcessingService_processAudio(
        JNIEnv* env,
        jobject /* this */,
        jshortArray input_array,
        jshortArray output_array,
        jint size) {
    try {
        if (audioProcessor == nullptr) {
            LOGE("Audio processor not initialized");
            return;
        }

        // Get input data from Java array
        jshort* input_ptr = env->GetShortArrayElements(input_array, nullptr);
        jshort* output_ptr = env->GetShortArrayElements(output_array, nullptr);

        if (input_ptr && output_ptr) {
            // Process audio
            audioProcessor->process(
                reinterpret_cast<short*>(input_ptr),
                reinterpret_cast<short*>(output_ptr),
                size
            );
        }

        // Release array elements
        env->ReleaseShortArrayElements(input_array, input_ptr, 0);
        env->ReleaseShortArrayElements(output_array, output_ptr, 0);
    } catch (const std::exception& e) {
        LOGE("Error processing audio: %s", e.what());
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_carkaraoke_audio_AudioProcessingService_releaseAudioProcessing(
        JNIEnv* env,
        jobject /* this */) {
    try {
        if (audioProcessor != nullptr) {
            delete audioProcessor;
            audioProcessor = nullptr;
            LOGD("Released audio processing resources");
        }
    } catch (const std::exception& e) {
        LOGE("Error releasing audio processing resources: %s", e.what());
    }
}
