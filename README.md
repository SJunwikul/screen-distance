# ScreenGuard - Eye Strain Prevention App

ScreenGuard is a native macOS application that monitors your distance from the screen using your MacBook's front-facing camera and alerts you when you're sitting too close, helping to reduce eye strain.

## Features

- **Real-time Distance Monitoring**: Uses face detection to calculate your distance from the screen
- **Smart Alerts**: Shows a modal warning when you're too close (less than 50cm)
- **Menu Bar Integration**: Runs quietly in the background with a menu bar icon
- **Auto-dismiss**: Warning modal disappears automatically when you move to a safe distance
- **Real-time Distance Display**: Shows current distance in both the menu bar and warning modal
- **Privacy-focused**: All processing happens locally on your device

## How It Works

1. **Face Detection**: Uses Apple's Vision framework to detect your face through the front camera
2. **Distance Calculation**: Calculates distance based on face size (larger face = closer distance)
3. **Calibration**: Automatically calibrates during the first 30 frames for accuracy
4. **Smart Thresholds**:
   - Minimum safe distance: 50cm
   - Optimal distance: 60-80cm
5. **Smooth Monitoring**: Uses moving average to prevent false alerts

## Installation

### Building from Source

1. **Prerequisites**:

   - macOS 14.0 or later
   - Xcode 15.0 or later

2. **Build Steps**:

   ```bash
   cd /your-repo-location/screen-distance
   xcodebuild -project ScreenGuard.xcodeproj -scheme ScreenGuard -configuration Release build
   OR
   ./build.sh
   ```

3. **Run the App**:
   ```bash
   open build/Build/Products/Release/ScreenGuard.app
   ```
   - Grant camera permissions when prompted
   - The app will appear in your menu bar with an eye icon

## Usage

1. **First Launch**:

   - Grant camera permission when prompted
   - The app will calibrate for ~3 seconds (sit at your normal distance)
   - Menu bar icon will show current distance

2. **Normal Operation**:

   - App runs silently in the background
   - Distance is displayed in the menu bar
   - Warning modal appears when you're too close
   - Modal shows real-time distance and disappears when you move back

3. **Menu Options**:
   - View current distance
   - Access preferences (coming soon)
   - Quit the application

## Privacy & Security

- **Local Processing**: All face detection and distance calculation happens on your device
- **No Data Collection**: No personal data is stored or transmitted
- **Camera Access**: Only used for face detection, no images are saved
- **Sandboxed**: App runs in Apple's security sandbox

## Health Benefits

ScreenGuard helps you maintain proper screen distance, which can:

- Reduce eye strain and fatigue
- Prevent dry eyes
- Improve posture
- Reduce risk of myopia progression
- Follow the 20-20-20 rule recommendations

## Technical Details

- **Built with**: Swift, AVFoundation, Vision Framework
- **Minimum Distance**: 50cm (recommended by eye care professionals)
- **Update Frequency**: 10 times per second for smooth monitoring
- **Face Detection**: Uses Apple's high-performance Vision framework
- **Distance Smoothing**: 5-frame moving average to prevent jitter

## Troubleshooting

### Camera Permission Issues

If the app can't access your camera:

1. Go to System Preferences > Privacy & Security > Camera
2. Enable access for ScreenGuard
3. Restart the application

### Distance Accuracy

- Ensure good lighting for accurate face detection
- Sit normally during the initial calibration period
- The app works best with consistent lighting conditions

### Performance

- Minimal CPU usage (~1-2%)
- Low memory footprint
- Designed for 24/7 operation

## Future Features

- [ ] Customizable distance thresholds
- [ ] Break reminders (20-20-20 rule)
- [ ] Usage statistics and reports
- [ ] Multiple user profiles
- [ ] Posture monitoring
- [ ] Integration with Health app

## System Requirements

- macOS 14.0 or later
- Front-facing camera (built-in or external)
- ~10MB disk space
- Camera permission

## License

This project is for personal use. Feel free to modify and adapt for your needs.

---

**Note**: This app is designed to help maintain healthy screen viewing habits. For persistent eye problems, consult an eye care professional.
