# MacPulse
MSCS_710L_711_25S PROJECT

## **Installation:**
---

1. Clone the repo: `git clone https://github.com/lgristina/macpulse.git`

2. Open in Xcode: open `MacPulse.xcodeproj`

3. Go to the MacPulse project file (top most file in project directory) and set the fields Team (AppleID) and Bundle Identifier under Signing & Capabilities.

4. Build and run for macOS and iOS (see below for initial iOS setup)

5. Starting with iOS 16, Apple requires you to manually enable Developer Mode to run apps directly from Xcode.

6. Plug in your iPhone via USB or use a trusted wireless connection.

7. Open Xcode on your Mac and build/run your app on the connected device.

---

### **On your iPhone, a Developer Mode prompt will appear:**
-Tap “Turn On”.

-Your iPhone will restart.

-After rebooting, go to:

-Settings > Privacy & Security > Developer Mode

-Toggle Developer Mode ON if it's not already.

-Tap Restart again if prompted.

### **Trust the Developer Certificate. On your iPhone:**
-Go to Settings > General > VPN & Device Management.

-Under Developer App, tap your Apple ID and tap Trust.

-This step is required only if you're using a free Apple ID or newly provisioned certificate.

### **Open your project in Xcode.**
-Select your physical iPhone from the target device list (at the top of Xcode).

-Press Cmd + R or click the Play button to build and run.

-If prompted to “Allow device for development,” confirm and enter your Mac password if required.

