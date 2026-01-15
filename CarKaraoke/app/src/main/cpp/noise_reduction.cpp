#include "noise_reduction.h"
#include <cstring>
#include <cmath>
#include <android/log.h>

#define TAG "NoiseReduction"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

NoiseReduction::NoiseReduction(int sampleRate) 
    : sampleRate_(sampleRate),
      noiseFloor_(0.0f),
      noiseEstimationAlpha_(0.9f),  // Smoothing factor for noise estimation
      reductionStrength_(0.8f),      // 80% noise reduction strength
      speechThreshold_(2.0f),        // Speech is 2x above noise floor
      fftSize_(512),                 // FFT size
      hopSize_(256) {                // 50% overlap

    // Initialize FFT-related buffers
    fftInput_.resize(fftSize_);
    fftOutputReal_.resize(fftSize_);
    fftOutputImag_.resize(fftSize_);
    magnitude_.resize(fftSize_ / 2);
    phase_.resize(fftSize_ / 2);
    noiseMagnitude_.resize(fftSize_ / 2, 0.0f);

    LOGD("Initialized noise reduction at %d Hz", sampleRate_);
}

NoiseReduction::~NoiseReduction() {
    LOGD("Released noise reduction resources");
}

void NoiseReduction::initFFT() {
    // In a real implementation, we would initialize a more efficient FFT library
    // like FFTW or the NDK's FFT functions
    LOGD("Initialized FFT with size %d", fftSize_);
}

void NoiseReduction::estimateNoiseFloor(float* magnitude, int size) {
    // Estimate noise floor using spectral subtraction approach
    for (int i = 0; i < size; ++i) {
        // Update noise magnitude estimate using smoothing
        noiseMagnitude_[i] = noiseEstimationAlpha_ * noiseMagnitude_[i] + 
                             (1.0f - noiseEstimationAlpha_) * magnitude[i];
    }
}

void NoiseReduction::applyNoiseReduction(float* magnitude, int size) {
    // Apply spectral subtraction for noise reduction
    for (int i = 0; i < size; ++i) {
        // Calculate signal-to-noise ratio (SNR)
        float snr = magnitude[i] / (noiseMagnitude_[i] + 1e-6f);
        
        if (snr > speechThreshold_) {
            // Speech detected, apply partial noise reduction
            float reduction = reductionStrength_ * (1.0f - speechThreshold_ / snr);
            magnitude[i] -= reduction * noiseMagnitude_[i];
        } else {
            // Noise only, apply full noise reduction
            magnitude[i] -= reductionStrength_ * noiseMagnitude_[i];
        }
        
        // Ensure magnitude doesn't go negative
        if (magnitude[i] < 0.0f) {
            magnitude[i] = 0.0f;
        }
    }
}

// Simple FFT implementation (for demonstration purposes only)
// In a real implementation, use a more efficient FFT library
void NoiseReduction::fft(float* input, float* outputReal, float* outputImag, int size) {
    // Clear output buffers
    memset(outputReal, 0, size * sizeof(float));
    memset(outputImag, 0, size * sizeof(float));
    
    // Copy input to real part of output
    memcpy(outputReal, input, size * sizeof(float));
    
    // Apply Hann window
    for (int i = 0; i < size; ++i) {
        float window = 0.5f * (1.0f - cos(2.0f * M_PI * i / (size - 1)));
        outputReal[i] *= window;
    }
    
    // Simple DFT implementation (inefficient for large sizes)
    for (int k = 0; k < size; ++k) {
        float real = 0.0f;
        float imag = 0.0f;
        for (int n = 0; n < size; ++n) {
            float angle = 2.0f * M_PI * k * n / size;
            real += outputReal[n] * cos(angle) + outputImag[n] * sin(angle);
            imag += -outputReal[n] * sin(angle) + outputImag[n] * cos(angle);
        }
        outputReal[k] = real;
        outputImag[k] = imag;
    }
}

// Simple IFFT implementation (for demonstration purposes only)
void NoiseReduction::ifft(float* inputReal, float* inputImag, float* output, int size) {
    // Clear output buffer
    memset(output, 0, size * sizeof(float));
    
    // Simple inverse DFT implementation
    for (int n = 0; n < size; ++n) {
        float real = 0.0f;
        float imag = 0.0f;
        for (int k = 0; k < size; ++k) {
            float angle = 2.0f * M_PI * k * n / size;
            real += inputReal[k] * cos(angle) - inputImag[k] * sin(angle);
            imag += inputReal[k] * sin(angle) + inputImag[k] * cos(angle);
        }
        // Normalize by FFT size
        output[n] = real / size;
    }
}

void NoiseReduction::process(short* input, short* output, int size) {
    // Convert input to float buffer
    floatBuffer_.resize(size);
    for (int i = 0; i < size; ++i) {
        floatBuffer_[i] = static_cast<float>(input[i]) / 32768.0f;  // Convert to [-1, 1]
    }
    
    // Process audio in frames with overlap
    int frameIndex = 0;
    while (frameIndex + fftSize_ <= size) {
        // Copy frame to FFT input buffer
        memcpy(fftInput_.data(), &floatBuffer_[frameIndex], fftSize_ * sizeof(float));
        
        // Apply FFT
        fft(fftInput_.data(), fftOutputReal_.data(), fftOutputImag_.data(), fftSize_);
        
        // Calculate magnitude and phase
        for (int i = 0; i < fftSize_ / 2; ++i) {
            magnitude_[i] = sqrt(fftOutputReal_[i] * fftOutputReal_[i] + 
                                fftOutputImag_[i] * fftOutputImag_[i]);
            phase_[i] = atan2(fftOutputImag_[i], fftOutputReal_[i]);
        }
        
        // Estimate noise floor
        estimateNoiseFloor(magnitude_.data(), fftSize_ / 2);
        
        // Apply noise reduction to magnitude
        applyNoiseReduction(magnitude_.data(), fftSize_ / 2);
        
        // Reconstruct complex spectrum from filtered magnitude and original phase
        for (int i = 0; i < fftSize_ / 2; ++i) {
            fftOutputReal_[i] = magnitude_[i] * cos(phase_[i]);
            fftOutputImag_[i] = magnitude_[i] * sin(phase_[i]);
            
            // Mirror the spectrum for IFFT
            fftOutputReal_[fftSize_ - 1 - i] = fftOutputReal_[i];
            fftOutputImag_[fftSize_ - 1 - i] = -fftOutputImag_[i];
        }
        
        // Apply inverse FFT to get time-domain signal
        float ifftOutput[fftSize_];
        ifft(fftOutputReal_.data(), fftOutputImag_.data(), ifftOutput, fftSize_);
        
        // Overlap-add to output buffer
        for (int i = 0; i < fftSize_; ++i) {
            if (frameIndex + i < size) {
                output[frameIndex + i] += static_cast<short>(ifftOutput[i] * 32768.0f);
            }
        }
        
        // Move to next frame with overlap
        frameIndex += hopSize_;
    }
    
    // Convert float buffer back to 16-bit PCM
    for (int i = 0; i < size; ++i) {
        // Clamp to valid range
        float sample = floatBuffer_[i];
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        
        output[i] = static_cast<short>(sample * 32768.0f);
    }
}
