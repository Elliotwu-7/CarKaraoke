#include "beamforming.h"
#include <cstring>
#include <cmath>
#include <android/log.h>

#define TAG "Beamforming"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

// Constants
const float SOUND_SPEED = 343.0f;  // Speed of sound in m/s
const float MICROPHONE_SPACING = 0.1f;  // Distance between microphones in meters

Beamforming::Beamforming(int sampleRate, int channels) 
    : sampleRate_(sampleRate), 
      channels_(channels), 
      targetAngle_(0.0f) {  // Default to front direction

    // Initialize beamforming coefficients for front direction
    calculateBeamformingCoefficients(targetAngle_);

    LOGD("Initialized beamforming with %d channels at %d Hz", channels_, sampleRate_);
}

Beamforming::~Beamforming() {
    LOGD("Released beamforming resources");
}

void Beamforming::calculateBeamformingCoefficients(float angle) {
    // Convert angle from degrees to radians
    float angleRad = angle * M_PI / 180.0f;
    
    // Resize coefficients vector
    beamformingCoefficients_.resize(channels_);
    
    // Calculate beamforming coefficients for each channel
    for (int i = 0; i < channels_; ++i) {
        // Assume a circular microphone array with uniform spacing
        float micAngle = (2.0f * M_PI * i) / channels_;
        
        // Calculate the delay for this microphone relative to the reference
        float delay = MICROPHONE_SPACING * cos(micAngle - angleRad) / SOUND_SPEED;
        
        // Convert delay to phase shift
        float phaseShift = 2.0f * M_PI * delay * sampleRate_;
        
        // For simplicity, we'll use real coefficients (delay-and-sum beamforming)
        // In a real implementation, we would use complex coefficients
        beamformingCoefficients_[i] = 1.0f / channels_;  // Equal weight for all channels
        // Note: For phase-shifted beamforming, we would need to use FFT
        // and apply phase shifts in the frequency domain
    }
}

float Beamforming::estimateDOA(short* input, int size) {
    // Simple DOA estimation using delay-and-sum for multiple angles
    int numFrames = size / channels_;
    float bestAngle = 0.0f;
    float maxEnergy = 0.0f;
    
    // Test angles from -90 to 90 degrees in 5-degree steps
    for (float angle = -90.0f; angle <= 90.0f; angle += 5.0f) {
        float energy = 0.0f;
        
        // Calculate beamforming coefficients for this angle
        calculateBeamformingCoefficients(angle);
        
        // Apply beamforming and calculate energy
        for (int frame = 0; frame < numFrames; ++frame) {
            float sum = 0.0f;
            for (int ch = 0; ch < channels_; ++ch) {
                int index = frame * channels_ + ch;
                sum += input[index] * beamformingCoefficients_[ch];
            }
            energy += sum * sum;
        }
        
        // Update best angle if this angle has higher energy
        if (energy > maxEnergy) {
            maxEnergy = energy;
            bestAngle = angle;
        }
    }
    
    return bestAngle;
}

void Beamforming::applyBeamforming(short* input, short* output, int size) {
    int numFrames = size / channels_;
    
    // For each frame, apply beamforming by summing weighted channels
    for (int frame = 0; frame < numFrames; ++frame) {
        float sum = 0.0f;
        for (int ch = 0; ch < channels_; ++ch) {
            int index = frame * channels_ + ch;
            sum += input[index] * beamformingCoefficients_[ch];
        }
        
        // Distribute the beamformed signal to all output channels
        // This maintains the original channel count for further processing
        for (int ch = 0; ch < channels_; ++ch) {
            int index = frame * channels_ + ch;
            output[index] = static_cast<short>(sum);
        }
    }
}

void Beamforming::process(short* input, short* output, int size) {
    // Step 1: Estimate DOA of the sound source
    float estimatedAngle = estimateDOA(input, size);
    
    // Step 2: Update beamforming coefficients if the angle has changed significantly
    if (fabs(estimatedAngle - targetAngle_) > 5.0f) {  // 5-degree threshold
        targetAngle_ = estimatedAngle;
        calculateBeamformingCoefficients(targetAngle_);
        LOGD("Updated beamforming angle to %.1f degrees", targetAngle_);
    }
    
    // Step 3: Apply beamforming to the input audio
    applyBeamforming(input, output, size);
}
