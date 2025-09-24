import Foundation
import AVFoundation
import Vision
import CoreImage

protocol DistanceMonitorDelegate: AnyObject {
    func distanceDidUpdate(_ distance: Double)
    func userIsTooClose(_ distance: Double)
    func userIsAtSafeDistance(_ distance: Double)
}

class DistanceMonitor: NSObject {
    weak var delegate: DistanceMonitorDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?
    
    private var lastFaceSize: CGFloat = 0
    private var baselineFaceSize: CGFloat = 0
    private var isCalibrating = true
    private var calibrationSamples: [CGFloat] = []
    private let calibrationSampleCount = 30
    
    // Distance thresholds (in cm)
    private let minSafeDistance: Double = 50.0  // 50cm minimum
    private let maxSafeDistance: Double = 80.0  // 80cm optimal
    
    private var isUserTooClose = false
    private var lastDistance: Double = 0
    
    // Smoothing
    private var distanceHistory: [Double] = []
    private let smoothingWindowSize = 5
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        guard let captureSession = captureSession else { return }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("Failed to create video device input")
            return
        }
        
        captureSession.addInput(videoDeviceInput)
        
        // Add video output
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
        
        if let videoDataOutput = videoDataOutput,
           let videoDataOutputQueue = videoDataOutputQueue,
           captureSession.canAddOutput(videoDataOutput) {
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            captureSession.addOutput(videoDataOutput)
        }
    }
    
    func startMonitoring() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        print("Distance monitoring started")
    }
    
    func stopMonitoring() {
        captureSession?.stopRunning()
        print("Distance monitoring stopped")
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Face detection error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first else {
                // No face detected
                return
            }
            
            self.processFaceDetection(face)
        }
        
        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }
    
    private func processFaceDetection(_ face: VNFaceObservation) {
        // Calculate face size (use width as primary measure)
        let faceSize = face.boundingBox.width
        
        if isCalibrating {
            calibrationSamples.append(faceSize)
            
            if calibrationSamples.count >= calibrationSampleCount {
                // Calculate baseline (average of samples)
                baselineFaceSize = calibrationSamples.reduce(0, +) / CGFloat(calibrationSamples.count)
                isCalibrating = false
                print("Calibration complete. Baseline face size: \(baselineFaceSize)")
            }
            return
        }
        
        guard baselineFaceSize > 0 else { return }
        
        // Calculate distance based on face size
        // Inverse relationship: larger face = closer distance
        let distance = calculateDistance(from: faceSize)
        
        // Smooth the distance readings
        addDistanceToHistory(distance)
        let smoothedDistance = getSmoothedDistance()
        
        lastDistance = smoothedDistance
        
        // Check if user is too close
        let wasTooClose = isUserTooClose
        isUserTooClose = smoothedDistance < minSafeDistance
        
        // Notify delegate
        delegate?.distanceDidUpdate(smoothedDistance)
        
        if isUserTooClose && !wasTooClose {
            delegate?.userIsTooClose(smoothedDistance)
        } else if !isUserTooClose && wasTooClose {
            delegate?.userIsAtSafeDistance(smoothedDistance)
        }
    }
    
    private func calculateDistance(from faceSize: CGFloat) -> Double {
        // Simple distance calculation based on face size
        // This is a rough approximation - in a real app you'd want more sophisticated calibration
        let ratio = baselineFaceSize / faceSize
        let baselineDistance = 60.0 // Assume 60cm as baseline distance
        
        return baselineDistance * Double(ratio)
    }
    
    private func addDistanceToHistory(_ distance: Double) {
        distanceHistory.append(distance)
        
        if distanceHistory.count > smoothingWindowSize {
            distanceHistory.removeFirst()
        }
    }
    
    private func getSmoothedDistance() -> Double {
        guard !distanceHistory.isEmpty else { return 0 }
        
        return distanceHistory.reduce(0, +) / Double(distanceHistory.count)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension DistanceMonitor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideoFrame(sampleBuffer)
    }
}
