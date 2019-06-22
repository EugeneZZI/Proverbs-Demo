# Proverbs Demo iOS Application

## Info
Service [web site].

AppStore [link].


### What does it use
- Firebase Authentication
- Firebase Firestore
- Firebase Storage
- Firebase Hosting
- AdMob
- Facebook
- Twitter
- Fabric
- Crashlytics
- In-App Purchases


### What to configure to run the App

**1) Configure Google Services plist file for firebase, ads and login**
- All keys for Google services
 (*SupportingFiles/GoogleService-Info.plist*) 
- URL Scheme
 (*Project settings or Info.plist*)
- AdMob App ID
 (*Info.plist*)
- AdMob banners IDs
 (*BannerViewController.swift*)

**2) Configure Facebook SDK for login and sharing**
- URL Scheme
 (*Project settings or Info.plist*)
- FacebookAppID
 (*Info.plist*)

**3) Configure Twitter SDK**
- URL Scheme
 (*Project settings or Info.plist*)
- Consumer Key and Secret
 (*AppDelegate.swift*)

**4) Configure Fabric with Crashlytics**
- Fabric run script
 (*Build Phases for target settings*)
 - Fabric API Key 
  (*Project settings or Info.plist*)
 
**5) Configure IAP**
- Set Product ID
 (*IAPController.swift*)


## Contact

Yevhenii(Eugene) Zozulia:

[https://www.linkedin.com/in/eugenezi/]

YevheniiZozulia@sezorus.com


## License

Proverbs Demo iOS App is available under the GNU General Public License v3.0 license. See the LICENSE file for more info.








[web site]: <https://www.saypro.me>
[link]: <https://itunes.apple.com/us/app/saypro/id1377175139>
[https://www.linkedin.com/in/eugenezi/]: <https://www.linkedin.com/in/eugenezi/>
