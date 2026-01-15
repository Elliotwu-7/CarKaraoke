#ifndef CAR_KARAOKE_AUDIO_PROCESSOR_H
#define CAR_KARAOKE_AUDIO_PROCESSOR_H

#include <cstdint>
#include <vector>

// Forward declarations
class MicrophoneArray;
class NoiseReduction;
class Beamforming;
class FeedbackCancellation;

/**
 * Main audio processor class that coordinates all audio processing modules
 */
class AudioProcessor {
public:
    /**
     * Constructor
     * @param sampleRate Sample rate in Hz
     * @param channels Number of input channels (microphone array channels)
     */
    AudioProcessor(int sampleRate, int channels);

    /**
     * Destructor
     */
    ~AudioProcessor();

    /**
     * Process audio data
     * @param input Input audio buffer (16-bit PCM)
     * @param output Output audio buffer (16-bit PCM)
     * @param size Number of samples in the input buffer
     */
    void process(short* input, short* output, int size);

private:
    int sampleRate_;  // Sample rate in Hz
    int inputChannels_;  // Number of input channels
    int outputChannels_;  // Number of output channels (stereo)

    // Audio processing modules
    MicrophoneArray* microphoneArray_;
    NoiseReduction* noiseReduction_;
    Beamforming* beamforming_;
    FeedbackCancellation* feedbackCancellation_;

    // Internal buffers
    std::vector<short> processedBuffer_;
    std::vector<short> monoBuffer_;
};

#endif // CAR_KARAOKE_AUDIO_PROCESSOR_H
