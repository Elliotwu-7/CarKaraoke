#include "audio_processor.h"
#include "microphone_array.h"
#include "noise_reduction.h"
#include "beamforming.h"
#include "feedback_cancellation.h"
#include <cstring>
#include <android/log.h>

#define TAG "AudioProcessor"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

AudioProcessor::AudioProcessor(int sampleRate, int channels) 
    : sampleRate_(sampleRate), 
      inputChannels_(channels), 
      outputChannels_(2),  // Stereo output
      microphoneArray_(nullptr),
      noiseReduction_(nullptr),
      beamforming_(nullptr),
      feedbackCancellation_(nullptr) {

    try {
        // Initialize audio processing modules
        microphoneArray_ = new MicrophoneArray(sampleRate_, inputChannels_);
        noiseReduction_ = new NoiseReduction(sampleRate_);
        beamforming_ = new Beamforming(sampleRate_, inputChannels_);
        feedbackCancellation_ = new FeedbackCancellation(sampleRate_);

        LOGD("Created audio processing modules");
    } catch (const std::exception& e) {
        LOGE("Failed to create audio processing modules: %s", e.what());
        throw;
    }
}

AudioProcessor::~AudioProcessor() {
    // Release audio processing modules
    delete feedbackCancellation_;
    delete beamforming_;
    delete noiseReduction_;
    delete microphoneArray_;

    LOGD("Released audio processing modules");
}

void AudioProcessor::process(short* input, short* output, int size) {
    // Ensure buffers are properly sized
    int numFrames = size / inputChannels_;
    processedBuffer_.resize(numFrames * inputChannels_);
    monoBuffer_.resize(numFrames);

    // Step 1: Microphone array processing (pre-processing)
    microphoneArray_->process(input, processedBuffer_.data(), size);

    // Step 2: Beamforming - focus on the main sound source
    beamforming_->process(processedBuffer_.data(), processedBuffer_.data(), size);

    // Step 3: Convert to mono for noise reduction
    for (int i = 0; i < numFrames; ++i) {
        // Simple average of all channels to get mono
        int sum = 0;
        for (int ch = 0; ch < inputChannels_; ++ch) {
            sum += processedBuffer_[i * inputChannels_ + ch];
        }
        monoBuffer_[i] = static_cast<short>(sum / inputChannels_);
    }

    // Step 4: Noise reduction
    noiseReduction_->process(monoBuffer_.data(), monoBuffer_.data(), numFrames);

    // Step 5: Feedback cancellation
    feedbackCancellation_->process(monoBuffer_.data(), monoBuffer_.data(), numFrames);

    // Step 6: Convert back to stereo for output
    for (int i = 0; i < numFrames; ++i) {
        output[i * 2] = monoBuffer_[i];      // Left channel
        output[i * 2 + 1] = monoBuffer_[i];  // Right channel
    }
}
