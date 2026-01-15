#include "microphone_array.h"
#include <cstring>
#include <android/log.h>

#define TAG "MicrophoneArray"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

MicrophoneArray::MicrophoneArray(int sampleRate, int channels) 
    : sampleRate_(sampleRate), 
      channels_(channels), 
      calibrationCoefficients_(nullptr) {

    // Initialize calibration coefficients
    calibrationCoefficients_ = new float[channels_];
    initCalibration();

    LOGD("Initialized microphone array with %d channels at %d Hz", channels_, sampleRate_);
}

MicrophoneArray::~MicrophoneArray() {
    delete[] calibrationCoefficients_;
    LOGD("Released microphone array resources");
}

void MicrophoneArray::initCalibration() {
    // Initialize calibration coefficients
    // In a real implementation, these would be loaded from a calibration file
    // For now, we'll use default values (1.0 for all channels)
    for (int i = 0; i < channels_; ++i) {
        calibrationCoefficients_[i] = 1.0f;
    }
    
    // Example calibration for 8-channel array
    if (channels_ == 8) {
        // Assume the center microphones are more sensitive
        calibrationCoefficients_[0] = 0.9f;  // Front left
        calibrationCoefficients_[1] = 1.0f;  // Front center left
        calibrationCoefficients_[2] = 1.1f;  // Front center
        calibrationCoefficients_[3] = 1.0f;  // Front center right
        calibrationCoefficients_[4] = 0.9f;  // Front right
        calibrationCoefficients_[5] = 0.8f;  // Rear left
        calibrationCoefficients_[6] = 0.8f;  // Rear center
        calibrationCoefficients_[7] = 0.8f;  // Rear right
    }
}

void MicrophoneArray::applyCalibration(short* input, short* output, int size) {
    int numFrames = size / channels_;
    
    for (int frame = 0; frame < numFrames; ++frame) {
        for (int ch = 0; ch < channels_; ++ch) {
            int index = frame * channels_ + ch;
            output[index] = static_cast<short>(input[index] * calibrationCoefficients_[ch]);
        }
    }
}

void MicrophoneArray::synchronizeChannels(short* input, short* output, int size) {
    // In a real implementation, this would handle channel synchronization
    // For now, we'll just copy the input to output (assuming channels are already synchronized)
    memcpy(output, input, size * sizeof(short));
}

void MicrophoneArray::process(short* input, short* output, int size) {
    // Step 1: Apply channel calibration
    applyCalibration(input, output, size);
    
    // Step 2: Synchronize channels
    synchronizeChannels(output, output, size);
    
    // Additional preprocessing steps could be added here
    // - DC offset removal
    // - Automatic gain control (AGC)
    // - Sample rate conversion (if needed)
}
