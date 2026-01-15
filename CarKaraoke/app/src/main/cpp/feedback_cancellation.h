#ifndef CAR_KARAOKE_FEEDBACK_CANCELLATION_H
#define CAR_KARAOKE_FEEDBACK_CANCELLATION_H

#include <cstdint>
#include <vector>

/**
 * Feedback Cancellation class
 * Implements adaptive feedback cancellation to prevent audio howling
 */
class FeedbackCancellation {
public:
    /**
     * Constructor
     * @param sampleRate Sample rate in Hz
     */
    FeedbackCancellation(int sampleRate);

    /**
     * Destructor
     */
    ~FeedbackCancellation();

    /**
     * Process audio data with feedback cancellation
     * @param input Input audio buffer (16-bit PCM, mono)
     * @param output Output audio buffer (16-bit PCM, mono)
     * @param size Number of samples in the input buffer
     */
    void process(short* input, short* output, int size);

private:
    int sampleRate_;  // Sample rate in Hz
    
    // Adaptive filter parameters
    int filterOrder_;  // Filter order (number of coefficients)
    float adaptationStep_;  // Adaptation step size
    
    // Adaptive filter coefficients
    std::vector<float> filterCoefficients_;
    
    // Delay line for input signal
    std::vector<float> delayLine_;
    
    // Error signal buffer
    std::vector<float> errorBuffer_;
    
    // Initialize adaptive filter
    void initAdaptiveFilter();
    
    // Apply adaptive feedback cancellation
    void applyFeedbackCancellation(float* input, float* output, int size);
    
    // Update filter coefficients using LMS algorithm
    void updateFilterCoefficients(float* input, float* error, int size);
    
    // Detect and suppress howling
    void detectAndSuppressHowling(float* input, float* output, int size);
};

#endif // CAR_KARAOKE_FEEDBACK_CANCELLATION_H
