#ifndef CAR_KARAOKE_NOISE_REDUCTION_H
#define CAR_KARAOKE_NOISE_REDUCTION_H

#include <cstdint>
#include <vector>

/**
 * Noise Reduction class
 * Implements AI-based noise reduction for car audio environment
 */
class NoiseReduction {
public:
    /**
     * Constructor
     * @param sampleRate Sample rate in Hz
     */
    NoiseReduction(int sampleRate);

    /**
     * Destructor
     */
    ~NoiseReduction();

    /**
     * Process audio data with noise reduction
     * @param input Input audio buffer (16-bit PCM, mono)
     * @param output Output audio buffer (16-bit PCM, mono)
     * @param size Number of samples in the input buffer
     */
    void process(short* input, short* output, int size);

private:
    int sampleRate_;  // Sample rate in Hz
    
    // Noise estimation parameters
    float noiseFloor_;  // Estimated noise floor level
    float noiseEstimationAlpha_;  // Smoothing factor for noise estimation
    
    // Noise reduction parameters
    float reductionStrength_;  // Noise reduction strength (0.0 to 1.0)
    float speechThreshold_;  // Threshold for speech detection
    
    // FFT-related parameters
    int fftSize_;  // FFT size
    int hopSize_;  // Hop size (overlap between frames)
    
    // Internal buffers
    std::vector<float> floatBuffer_;
    std::vector<float> fftInput_;
    std::vector<float> fftOutputReal_;
    std::vector<float> fftOutputImag_;
    std::vector<float> magnitude_;
    std::vector<float> phase_;
    std::vector<float> noiseMagnitude_;
    
    // Initialize FFT
    void initFFT();
    
    // Estimate noise floor from the input signal
    void estimateNoiseFloor(float* magnitude, int size);
    
    // Apply noise reduction to the magnitude spectrum
    void applyNoiseReduction(float* magnitude, int size);
    
    // Simple FFT implementation (in a real implementation, we would use a library like FFTW)
    void fft(float* input, float* outputReal, float* outputImag, int size);
    
    // Inverse FFT
    void ifft(float* inputReal, float* inputImag, float* output, int size);
};

#endif // CAR_KARAOKE_NOISE_REDUCTION_H
