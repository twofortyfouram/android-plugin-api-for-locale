# Archived
This repository has been archived in favor of a new single repository located [here](https://github.com/twofortyfouram/android-monorepo).

# Overview
[Locale X](https://play.google.com/store/apps/details?id=com.twofortyfouram.locale.x) allows developers to create plug-in conditions and settings. Interaction between Locale (host) and plug-ins (client) occurs via an Intent-based API.  This repo contains the definition for that Intent-based API.  The Intent-based API is the lowest level layer of the plug-in API for Locale.

Although there are multiple ways to approach building a plug-in host or plug-in client, we do not recommend starting with this API layer.  Instead we strongly recommend starting with the main [Plug-in API for Locale](http://www.twofortyfouram.com/developer).


# API Reference
JavaDocs for the library are published [here](http://twofortyfouram.github.io/android-plugin-api-for-locale/).


# Compatibility
The library is compatible and optimized for Android API Level 1 and above.


# Download
## Gradle
The library is published as an artifact to jCenter.  To use the library, the jCenter repository and the artifact need to be added to your build script.

The build.gradle repositories section would look something like the following:

    repositories {
        jcenter()
    }

And the dependencies section would look something like this:
    
    dependencies {
        compile group:'com.twofortyfouram', name:'android-plugin-api-for-locale', version:'[1.0.2,2.0['
    }


# Intent API Specification
There are two perspectives to look at the Intent API from: the client and the host.  Because clients significantly outnumber hosts, let's cover clients first.

## Client
A plug-in implementation consists of two things:

1. Activity: for the [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION) or [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING) Intent action.
1. BroadcastReceiver: for the [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) or [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) Intent action.

### Activity for Editing
When the user taps on a plug-in in the host, the "edit" action (either [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION) or [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING)) is explicitly broadcast to launch the edit Activity exported by the plug-in's AndroidManifest.

Once the user has completed configuring the plug-in, the plug-in's Activity result Intent back to the host MUST contain the following:

1. [RESULT_OK](http://developer.android.com/reference/android/app/Activity.html#RESULT_OK): indicates the plug-in instance should be saved and therefore the following extras are required.
    1. Blurb Extra: Constant key value [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) maps to a String extra that represents a concise, human-readable status of the plug-in instance. For example, a Wi-Fi toggle setting might have a blurb that says, "Off".
    1. Bundle Extra: Constant key value [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) maps to a Bundle that represents the entire state of the plug-in. This Bundle is stored by the host and sent back to the plug-in whenever the plug-in is edited again or eventually queried/fired.    
1. [RESULT_CANCELED](http://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED): indicates that changes should not be saved and no blurb or Bundle are required.

### BroadcastReceiver for Querying Conditions
When the host queries a plug-in condition, the host will send an explicit ordered Intent with the action [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) to the BroadcastReceiver exported by the plug-in's AndroidManifest. This Intent will contain the [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) extra that was previously saved by the edit Activity.

The host makes no guarantees as to how often or if the plug-in will be queried. The order in which conditions are queried is unspecified. Typically, a plug-in will be queried once when the host first starts up, and additional queries may happen at any time. In addition to waiting for the host to query the plug-in, a plug-in can signal to the host that it is ready to be queried via the [ACTION_REQUEST_QUERY](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_REQUEST_QUERY) Intent. If a plug-in instance does not receive a response to [ACTION_REQUEST_QUERY](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_REQUEST_QUERY) within one minute, the plug-in instance SHOULD stop requesting requeries as no response indicates that the host is not currently interested in that plug-in.

It may not be possible to implement all conceivable plug-in conditions with this interface. Plug-ins that operate asynchronously (e.g. they receive actions like ACTION_POWER_CONNECTED and then broadcast [ACTION_REQUEST_QUERY](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_REQUEST_QUERY) to the host) or plug-ins that can respond to a query Intent immediately, such as a calendar plug-in, will work best. Plug-ins that require a background service to operate are not recommended, as each running service (and associated process) consumes additional RAM which is limited resource on an Android device.

### BroadcastReceiver for Firing Settings
When it comes time to fire a plug-in setting, the host will send an explicit Intent with the action [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) to the BroadcastReceiver exported by the plug-in's AndroidManifest. This Intent will contain the [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) extra that was previously saved by the edit Activity.

## Host
Fundamentally, a host interacts with plug-ins in four phases: scan, edit, persist, and execute.

### Scan
The host uses the Android Package Manager to scan for plug-ins installed on the device.  In the host, a plug-in is uniquely identified by the combination of Android package name and the "edit" Activity class name.

### Edit
Typically a host will present a list of scanned plug-ins to the user, and the user selects which plug-in to edit.  The host constructs an explicit Intent for either the [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION) or [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING) Intent action, calls [startActivityForResult(Intent, int)](http://developer.android.com/reference/android/app/Activity.html#startActivityForResult(android.content.Intent,%20int)), and waits for the Activity result.

### Persist
Assuming the plug-in Activity returns RESULT_OK with all of the necessary extras, the host persists the plug-in instance data.  At a minimum, the host must persist the plug-in's type {condition, setting}, Android package name, Activity class name, serialized bundle, and blurb.  The BroadcastReceiver class name is not persisted, because it is determined dynamically during the host's scan phase.

### Execute
At some point in the future, the host wants to query a plug-in condition instance or fire a plug-in setting instance.  The host reads in the persisted {type, package, Activity, Bundle} tuple and broadcasts the appropriate explicit Intent action.

## The gritty details
Creating an Intent-based specification is complicated.  This section is intended to be explicitly clear and resolve all ambiguity as to how the API works.

### Intents
1. All communication between host and plug-in MUST be through the appropriate Intent action defined by the API: [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING), [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION), [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION), [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING), [ACTION_REQUEST_QUERY](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_REQUEST_QUERY).
1. All Intents MUST contain the appropriate extras defined by the API: [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE), [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB), [EXTRA_STRING_BREADCRUMB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BREADCRUMB), [EXTRA_STRING_ACTIVITY_CLASS_NAME](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_ACTIVITY_CLASS_NAME).
1. Intents SHOULD NOT contain extras other than those defined by the API.  While some third party hosts may wish to incorporate additional Intent extras, this is not recommended because these extras create a fragmented API with reduced compatibility.  If such extras are used, they MUST only provide additional functionality that is impossible to achieve using the existing API.  In addition, these extras MUST NOT be a requirement for the plug-in to operate.  Hosts have no way to differentiate between plug-ins requiring special extras and those not requiring special extras.  In order to ensure that all plug-ins work with all hosts, a plug-in MUST assume that the host does not support special extras.  Unsupported Intent extras MUST NOT use the com.twofortyfouram namespace for extras.  The com.twofortyfouram namespace is reserved for future use by the API.
1. [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING), [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION), [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION), [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING) MUST be explicit Intents (containing the plug-in's package name and component class name).
1. [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) and [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) MUST be broadcast with the flag [FLAG_INCLUDE_STOPPED_PACKAGES](http://developer.android.com/reference/android/content/Intent.html#FLAG_INCLUDE_STOPPED_PACKAGES).  On Android API level 12 and greater, this flag ensures that if the user restores the host from a backup, plug-ins will continue functioning in the background without requiring that the user open the plug-ins' UIs.
1. [ACTION_REQUEST_QUERY](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_REQUEST_QUERY) MUST NOT be broadcast with the flag [FLAG_INCLUDE_STOPPED_PACKAGES](http://developer.android.com/reference/android/content/Intent.html#FLAG_INCLUDE_STOPPED_PACKAGES).
1. [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) and [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) SHOULD be broadcast with the flag [FLAG_FROM_BACKGROUND](http://developer.android.com/reference/android/content/Intent.html#FLAG_FROM_BACKGROUND) when they are broadcast as the result of an automatic change in the host and not as a result of direct user interaction.
1. [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) and [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) MUST be background priority Intents.  In other words, these Intents MUST NOT have the flag [FLAG_RECEIVER_FOREGROUND](http://developer.android.com/reference/android/content/Intent.html#FLAG_RECEIVER_FOREGROUND).
1. [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) MAY be sent as an ordered broadcast, if the host wishes to block until the setting completes.  In this case, the ordered broadcast result code and extras have no meaning although the API reserves the right to assign meaning to these in the future.
1. [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) MUST be sent as an ordered broadcast.
1. All Intents MUST NOT contain data, flags, categories, source bounds, or any other fields in the Intent object not otherwise specified by this API.  Additional data, flags, categories, and other information are reserved for future use by the API.

### Client
1. A plug-in MUST be configured to only install to internal memory, in order to meet Android's [guidelines for app install locations](http://developer.android.com/guide/topics/data/install-location.html#ShouldNot).  Plug-ins that are installed on external memory will not behave reliably or consistently.
1. When saving a plug-in instance, the plug-in Activity MUST NOT store private information—such as login credentials—in [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE).  Doing so would constitute a serious security flaw because Android allows any application with the [GET_TASKS](http://developer.android.com/reference/android/Manifest.permission.html#GET_TASKS) permission to read the Intent sent by the host to a plug-in Activity through [ActivityManager.getRecentTasks(int, int)](http://developer.android.com/reference/android/app/ActivityManager.html#getRecentTasks(int,%20int)). If a plug-in needs to store login credentials, there are more secure implementations. Remember that each app on Android with a unique digital signature will run in its own sandbox. To improve security of private data, such as usernames and passwords, only minimal information needs to be passed to the host via [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE). For example, consider a hypothetical plug-in setting that posts a Tweet to Twitter. It could store OAuth credentials in a SharedPreference file private to the plug-in and only returns the non-private Tweet message via [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE).
1. When saving a plug-in instance, the plug-in Activity SHOULD NOT modify the [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) or [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) unnecessarily.  For example, a plug-in SHOULD NOT store timestamp in the Bundle, because this guarantees that the plug-in will appear as modified when it is returned to the host.  Host implementations MAY compare the current result of a plug-in Activity to the previous result, in order to decide whether the new result should be saved.
1. When saving a plug-in instance, the plug-in Activity MUST return a non-null [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) extra.  The blurb SHOULD NOT be an empty string.
1. When saving a plug-in instance, [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) MUST  be less than 25 kilobytes (base-10) when serialized by the host.  While the serialization mechanism used by the host is opaque to the plug-in, in general plug-ins should just make their Bundle compact. In Android, Intent extras are limited to about 500 kilobytes, although the exact size is not specified by the Android public API.  If an Intent exceeds that size, the extras will be silently dropped by Android. In Android 4.4 KitKat, the maximum amount of data that can be written to a ContentProvider during a ContentProviderOperation was reduced to less than 300 kilobytes. The maximum bundle size here was chosen to allow several large plug-ins to be added to a single batch of operations that might occur internally in the host before overflow occurs.
1. When saving a plug-in instance, [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) MUST NOT contain Parcelable objects, because these cannot be stored long-term. Instead of Parcelable, use Serializable.
1. When saving a plug-in instance, [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) MUST only contain objects that are part of the standard Android platform, because the host's class loader will need to serialize and deserialize these objects.
1. Plug-ins SHOULD NOT store any serializable object that is not available across all Android API levels that the plug-in supports.  Doing could cause previously saved plug-ins to fail during backup and restore.  This is a contrived example, but demonstrates the problem: A plug-in supports Android API level 8 through 19.  When running on API level 19, the plug-in includes a Serializable class only present in API level 19 such as [ReflectiveOperationException](http://developer.android.com/reference/java/lang/ReflectiveOperationException.html).  If the host's data is ever backed up and restored to a device running an older API level, the host would encounter an exception because the Serializable class cannot be found.
1. A plug-in SHOULD NOT keep state about what instances have been created, as the user could delete these from within the host at any time.
1. A plug-in MUST NOT assume that only a single host will be executing it at a time: a user may have multiple hosts installed simultaneously.
1. A plug-in SHOULD NOT duplicate host functionality.  If a plug-in has functionality similar to the host, it MUST NOT be described in a way that misrepresents its use.  For example, a condition plug-in that uses Wi-Fi SSID or MAC address should identify itself as a "Wi-Fi" condition and not an alternative "Location" condition.  Similarly, a condition plug-in that uses cell tower IDs should not advertise itself as a "Cell Location" or "Location (energy-saving)" plug-in but rather a "Cell ID" plug-in.  In addition, a plug-in MUST NOT advertise functionality with the exact same name as a feature in the host.  For example, a plug-in SHOULD NOT call itself a "Location" condition when the host already contains such functionality.
1. A plug-in SHOULD NOT disrupt the functionality of the host.  If a plug-in has the potential to disrupt functionality in the host, it MUST present the user with a disclaimer.  For example, a plug-in that disables the Internet connection should say "Disabling the Internet connection may prevent apps from determining your location."
1. A plug-in MUST ignore unknown Intent extras, data, flags, or other parameters not specified by this API.  This provides compatibility with other hosts that wish to specify their own extras and also enables possible forward-compatibility with future improvements to this API.

### Host
#### Scan
1. A host MUST reject a plug-in that does not implement both an edit Activity and a BroadcastReceiver of the same type (e.g. must implement both [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING) and [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) or must implement both [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION) and [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION)).
1. A host MUST reject a plug-in that contains multiple [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) or [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) BroadcastReceivers.  This is because multiple BroadcastReceivers are ambiguous.
1. A host MUST accept a plug-in that has multiple [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING) Activities, multiple [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION) Activities, or some number of both, as long as there is a single corresponding [ACTION_FIRE_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_FIRE_SETTING) or [ACTION_QUERY_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_QUERY_CONDITION) BroadcastReceiver.
1. A host MUST check that it has permission to send Intents to a plug-in's Edit Activity and BroadcastReceiver.  Plug-ins that do not meet this criteria MUST be rejected.
1. A host MUST check that a plug-in's Edit Activity and BroadcastReceiver are both exported.  Plug-ins that do not meet these criteria MUST be rejected.
1. A host MUST check that a plug-in's Edit Activity and BroadcastReceiver are both exanbled.  Plug-ins that do not meet these criteria MUST be rejected.
1. A host MUST check that a plug-in's Application is enabled.  Plug-ins that do not meet this criteria MUST be rejected.  
1. A host MUST check that a plug-in is configured to only be installed on internal memory.  Plug-ins that do not meet this criteria MUST be rejected.
1. A host SHOULD check that a plug-in's Edit Activity implements both a label and icon attribute.  Plug-ins that do not meet this criteria SHOULD be alerted via a logcat warning.  (Plug-ins that do not implement these do not provide the best user experience by optimizing the label and icon of the plug-in shown in the host's UI).
1. A host SHOULD print a logcat message when rejecting a plug-in explaining why rejection occurred and how the rejection could be resolved.  This message is intended for the plug-in developer, not the end user.  If all hosts properly implement the rejection requirements described in this document, then it should be impossible for a developer to release a plug-in that is incompatible with any given host.
1. A host SHOULD check that the plug-in's targetSdkVersion is at least the same value of the host's.  If the host targets a newer SDK than the plug-in, the host SHOULD print a logcat message.  A host MUST NOT reject a plug-in for targeting an older SDK.  This message is intended for the plug-in developer, to ensure the plug-in is not running in Android's compatibility mode and causing an inconsistent user experience.  When the user edits a plug-in, the experience should feel seamless as if the user was editing functionality native to the host.
1. A host SHOULD check that a plug-in's icon attribute is the correct size (LDPI 27x27, MDPI 36x36, HDPI 48x48, XHDPI 72x72).  A host MUST NOT reject a plug-in whose icon is the wrong size, but SHOULD print a logcat message.
1. A host SHOULD detect changes to plug-ins immediately, including installation, uninstallation, changes to permissions, changes to component enabled/disabled status, changes to install location, changes to name or icon due to a UI configuration change, etc.  For example, if the host is running and a new plug-in is installed, that new plug-in should appear in the host's UI immediately without requiring the user to leave the UI and return.

#### Edit
1. An edit Intent for a condition MUST contain the action [ACTION_EDIT_CONDITION](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_CONDITION), while an edit Intent for a setting MUST contain the action [ACTION_EDIT_SETTING](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#ACTION_EDIT_SETTING).  This tells the plug-in Activity that it is being started for the purposes of being a plug-in.  Some third party apps use a single Activity for both a plug-in as well as other functionality within the app.  By providing an Intent action, these plug-ins are able to distinguish between different launch reasons.
1. An edit Intent MUST contain an explicit component name.  This guarantees that the edit Intent goes to the intended recipient.
1. An edit Intent MUST contain [EXTRA_STRING_BREADCRUMB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BREADCRUMB) that is associated with a String value.  This String MUST NOT be null and SHOULD NOT be the empty string.  This String SHOULD be a representation of the previous Activity's title.
1. The host MUST wrap the launch of the edit Intent in a try-catch block that catches both ActivityNotFoundException and SecurityException.  This prevents a number of TOCTOU (time of check to time of use) and security issues where a plug-in could be uninstalled just before it is launched or a malicious plug-in could even change its permissions right before launch.
1. The host MUST start a plug-in Activity by calling [startActivityForResult(Intent, int)](http://developer.android.com/reference/android/app/Activity.html#startActivityForResult(android.content.Intent,%20int)).
1. [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) MUST only be present if an old instance of the plug-in is being edited.  If [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) is present in the edit Intent, it MUST NOT be null.  It may be an empty Bundle however, if the plug-in previously returned an empty Bundle.
1. [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) MUST only be present if an old instance of the plug-in is being edited.  If [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) is present in the edit Intent, it MUST NOT be null.

#### Persist
1. When a plug-in's Activity result code is RESULT_CANCELED, a host must treat this as a cancelation.  If a new plug-in instance was being edited, then the host does nothing.  If an old plug-in instance was being edited, the old plug-in instance MUST NOT be deleted.
1. When a plug-in's Activity result code is RESULT_OK, the host MUST:
    1. Treat RESULT_OK as a save when [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) and [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) are valid.
    1. Reject null Intents and treat them as a cancellation
    1. Reject Intents with a null [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) and treat them as a cancellation
    1. Reject Intents with a null [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) and treat them as a cancellation
    1. Reject [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE)s that contain parcelable classes that aren't serializable and treat them as a cancellation
    1. Reject [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE)s that contain private serializable subclasses and treat them as a cancellation
    1. Reject [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE)s that are over 25kb (base-10) in size after serialization and treat them as a cancellation
    1. Ignore unknown extras: This provides compatibility with other hosts that wish to specify their own extras.
1. A host MUST treat all unrecognized result codes as RESULT_CANCELED and a host SHOULD print a logcat message indicating this result code is not valid.
1. A host MUST NOT mutate the [EXTRA_BUNDLE](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_BUNDLE) or [EXTRA_STRING_BLURB](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#EXTRA_STRING_BLURB) saved by the plug-in.
1. A host MUST be able to store all data types returned from a plug-in, including sub-Bundles, null keys, null values, arrays, etc.  (With the exception of rejecting private serializable subclasses and Parcelable classes.)
1. When a plug-in instance is deleted within the host, the host MUST NOT notify the plug-in that a deletion has occurred.  While at first glance this seems reasonable, there are corner cases where the host will not be able to notify the plug-in.  For example, the user could clear the host's data via the Android settings.  When the host's data is cleared, the host is unaware and therefore the host will not have the opportunity to notify plug-ins.

#### Execute
1. An execute Intent for a condition MUST contain an initial result code in the set {[RESULT_CONDITION_SATISFIED](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#RESULT_CONDITION_UNSATISFIED), [RESULT_CONDITION_UNKNOWN](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#RESULT_CONDITION_UNKNOWN), [RESULT_CONDITION_UNKNOWN](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#RESULT_CONDITION_UNKNOWN)}.  If the host knows the previous state of the condition, it SHOULD set the initial result code to that previous state, as this MAY be used by the plug-in to determine its initial value.  If the host does not know the previous state of the condition, it MUST set the initial result code to [RESULT_CONDITION_UNKNOWN](http://twofortyfouram.github.io/android-plugin-api-for-locale/com/twofortyfouram/locale/api/Intent.html#RESULT_CONDITION_UNKNOWN).

# History
* 1.0.0: Initial release
* 1.0.2: Reupload artifacts with source and JavaDoc for inclusion in jCenter
