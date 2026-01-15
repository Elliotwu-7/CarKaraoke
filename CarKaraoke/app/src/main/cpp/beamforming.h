#ifndef CAR_KARAOKE_BEAMFORMING_H
#define CAR_KARAOKE_BEAMFORMING_H

#include <cstdint>
#include <vector>

/**
 * Beamforming class
 * Implements adaptive beamforming to focus on the main sound source
 */
class Beamforming {
public:
    /**
     * Constructor
     * @param sampleRate Sample rate in Hz
     * @param channels Number of microphone channels
     */
    Beamforming(int sampleRate, int channels);

    /**
     * Destructor
     */
    ~Beamforming();

    /**
     * Process audio data with beamforming
     * @param input Input audio buffer (16-bit PCM)
     * @param output Output audio buffer (16-bit PCM)
     * @param size Number of samples in the input buffer
     */
    void process(short* input, short* output, int size);

private:
    int sampleRate_;  // Sample rate in Hz
    int channels_;    // Number of microphone channels
    float targetAngle_;  // Target angle in degrees (0 = front)

    // Beamforming coefficients
    std::vector<float> beamformingCoefficients_;

    // Initialize beamforming coefficients for a specific angle
    void calculateBeamformingCoefficients(float angle);

    // Apply beamforming to the input audio
    void applyBeamforming(short* input, short* output, int size);

    // Estimate the direction of arrival (DOA) of the sound source
    float estimateDOA(short* input, int size);
};

#endif // CAR_KARAOKE_BEAMFORMING_H
