#include "feedback_cancellation.h"
#include <cstring>
#include <cmath>
#include <android/log.h>

#define TAG "FeedbackCancellation"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

// Constants for howling detection
const float HOWLING_THRESHOLD = 0.9f;  // Normalized amplitude threshold for howling
const float HOWLING_DURATION_THRESHOLD = 0.1f;  // Duration in seconds
const float HOWLING_SUPPRESSION_GAIN = 0.3f;  // Gain reduction during howling

FeedbackCancellation::FeedbackCancellation(int sampleRate) 
    : sampleRate_(sampleRate),
      filterOrder_(256),  // Filter order for adaptive feedback cancellation
      adaptationStep_(0.01f) {  // Adaptation step size

    // Initialize adaptive filter
    initAdaptiveFilter();

    LOGD("Initialized feedback cancellation at %d Hz", sampleRate_);
}

FeedbackCancellation::~FeedbackCancellation() {
    LOGD("Released feedback cancellation resources");
}

void FeedbackCancellation::initAdaptiveFilter() {
    // Initialize filter coefficients to zero
    filterCoefficients_.resize(filterOrder_, 0.0f);
    
    // Initialize delay line for input signal
    delayLine_.resize(filterOrder_, 0.0f);
    
    // Initialize error buffer
    errorBuffer_.resize(filterOrder_, 0.0f);

    LOGD("Initialized adaptive filter with %d coefficients", filterOrder_);
}

void FeedbackCancellation::applyFeedbackCancellation(float* input, float* output, int size) {
    // Process audio with adaptive feedback cancellation
    for (int i = 0; i < size; ++i) {
        // Shift delay line
        for (int j = filterOrder_ - 1; j > 0; --j) {
            delayLine_[j] = delayLine_[j - 1];
        }
        
        // Add current input to delay line
        delayLine_[0] = input[i];
        
        // Apply adaptive filter to estimate feedback
        float estimatedFeedback = 0.0f;
        for (int j = 0; j < filterOrder_; ++j) {
            estimatedFeedback += filterCoefficients_[j] * delayLine_[j];
        }
        
        // Subtract estimated feedback from input to get output
        output[i] = input[i] - estimatedFeedback;
        
        // Store error signal for filter update
        errorBuffer_[i % filterOrder_] = output[i];
    }
}

void FeedbackCancellation::updateFilterCoefficients(float* input, float* error, int size) {
    // Update filter coefficients using LMS algorithm
    for (int i = 0; i < size; ++i) {
        // Update each filter coefficient
        for (int j = 0; j < filterOrder_; ++j) {
            // Get delayed input sample
            int delayIndex = (i - j + filterOrder_) % filterOrder_;
            float delayedInput = (delayIndex < size) ? input[delayIndex] : 0.0f;
            
            // Update coefficient using LMS rule
            filterCoefficients_[j] += adaptationStep_ * error[i] * delayedInput;
            
            // Normalize coefficients to prevent overflow
            if (fabs(filterCoefficients_[j]) > 1.0f) {
                filterCoefficients_[j] = copysign(1.0f, filterCoefficients_[j]);
            }
        }
    }
}

void FeedbackCancellation::detectAndSuppressHowling(float* input, float* output, int size) {
    // Simple howling detection based on signal amplitude and frequency content
    // In a real implementation, this would use more sophisticated algorithms
    
    // Detect howling by looking for sustained high-amplitude signals
    int howlingCount = 0;
    for (int i = 0; i < size; ++i) {
        if (fabs(input[i]) > HOWLING_THRESHOLD) {
            howlingCount++;
        }
    }
    
    // Calculate howling duration
    float howlingDuration = static_cast<float>(howlingCount) / sampleRate_;
    
    // If howling is detected, apply suppression gain
    if (howlingDuration > HOWLING_DURATION_THRESHOLD) {
        LOGD("Howling detected! Applying suppression gain");
        for (int i = 0; i < size; ++i) {
            output[i] *= HOWLING_SUPPRESSION_GAIN;
        }
    }
}

void FeedbackCancellation::process(short* input, short* output, int size) {
    // Convert input to float buffer [-1, 1]
    std::vector<float> floatInput(size);
    std::vector<float> floatOutput(size);
    
    for (int i = 0; i < size; ++i) {
        floatInput[i] = static_cast<float>(input[i]) / 32768.0f;
    }
    
    // Step 1: Apply adaptive feedback cancellation
    applyFeedbackCancellation(floatInput.data(), floatOutput.data(), size);
    
    // Step 2: Update filter coefficients using error signal
    updateFilterCoefficients(floatInput.data(), floatOutput.data(), size);
    
    // Step 3: Detect and suppress any remaining howling
    detectAndSuppressHowling(floatOutput.data(), floatOutput.data(), size);
    
    // Step 4: Apply post-processing for AFC残差抑制 and 音质失真补偿
    // In a real implementation, this would include more sophisticated processing
    
    // Convert float output back to 16-bit PCM
    for (int i = 0; i < size; ++i) {
        // Clamp to valid range
        float sample = floatOutput[i];
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        
        output[i] = static_cast<short>(sample * 32768.0f);
    }
}
