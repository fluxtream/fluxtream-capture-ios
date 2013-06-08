fluxtream-capture-ios
=====================

Fluxtream capture for iOS.  Records and uploads:

- Location
- Motion (10 Hz, acceleration and orientation)
- Photos, with tags and comments
- Heart rate and R-R timings for every heart beat from Polar H7.
  Heart rate requires hardware with Bluetooth Low Energy (BLE, or Bluetooth Smart) support, such as
  - iPhone 4s, 5, or later
  - iPad 3, 4, or later
  - iPod 4th generation, or later

More info on heart rate capture, R-R timings, and heart rate variability (HRV) at https://docs.google.com/document/d/1eEdfpfL9Jy9EX9_FvWuDv7pA_mWHkcgZfS6ggxaTZD0/edit

BUILDING

Fluxtream Capture is written in Objective C and C++.  Simply open FluxtreamCapture.xcodeproj in Xcode 4.6.2+, connect your iPhone, and hit command-R to build and run on your phone.

More info on building and distributing the app at the Fluxtream wiki, https://fluxtream.atlassian.net/wiki/display/FLX/Fluxtream+Capture+iOS+Development
