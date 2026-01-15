#ifndef CAR_KARAOKE_MICROPHONE_ARRAY_H
#define CAR_KARAOKE_MICROPHONE_ARRAY_H

#include <cstdint>

/**
 * Microphone array processing class
 * Handles pre-processing of multi-channel microphone input
 */
class MicrophoneArray {
public:
    /**
     * Constructor
     * @param sampleRate Sample rate in Hz
     * @param channels Number of microphone channels
     */
    MicrophoneArray(int sampleRate, int channels);

    /**
     * Destructor
     */
    ~MicrophoneArray();

    /**
     * Process microphone array audio data
     * @param input Input audio buffer (16-bit PCM)
     * @param output Output audio buffer (16-bit PCM)
     * @param size Number of samples in the input buffer
     */
    void process(short* input, short* output, int size);

private:
    int sampleRate_;  // Sample rate in Hz
    int channels_;    // Number of microphone channels

    // Calibration coefficients for each channel
    float* calibrationCoefficients_;

    // Initialize calibration coefficients
    void initCalibration();

    // Apply calibration to microphone channels
    void applyCalibration(short* input, short* output, int size);

    // Synchronize microphone channels
    void synchronizeChannels(short* input, short* output, int size);
};

#endif // CAR_KARAOKE_MICROPHONE_ARRAY_H
