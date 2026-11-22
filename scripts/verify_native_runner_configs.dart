// Universal QR Platform — Native Runner Configuration Auditor
// Verifies application IDs, display names, permissions, and runner configurations
// across Android, iOS, Windows, Linux, and macOS for both User App and Admin App.

import 'dart:io';

void main() {
  print('=== Universal QR Native Runner Config Auditor ===');

  final rootDir = Directory.current;
  final userAppDir = Directory('${rootDir.path}/apps/user_app');
  final adminAppDir = Directory('${rootDir.path}/apps/admin_app');

  if (!userAppDir.existsSync() || !adminAppDir.existsSync()) {
    stderr.writeln('ERROR: Could not locate apps/user_app or apps/admin_app.');
    exit(1);
  }

  int passCount = 0;
  int failCount = 0;

  void assertRule(String checkName, bool condition, String failureDetails) {
    if (condition) {
      print('  [PASS] $checkName');
      passCount++;
    } else {
      stderr.writeln('  [FAIL] $checkName: $failureDetails');
      failCount++;
    }
  }

  final platforms = ['android', 'ios', 'windows', 'linux', 'macos'];

  print('\n[1] Verifying Platform Runner Directory Existence:');
  for (final platform in platforms) {
    final userPlatformDir = Directory('${userAppDir.path}/$platform');
    final adminPlatformDir = Directory('${adminAppDir.path}/$platform');

    assertRule(
      'apps/user_app/$platform exists',
      userPlatformDir.existsSync(),
      'Directory missing: ${userPlatformDir.path}',
    );
    assertRule(
      'apps/admin_app/$platform exists',
      adminPlatformDir.existsSync(),
      'Directory missing: ${adminPlatformDir.path}',
    );
  }

  print('\n[2] Verifying Application IDs (com.universalqr.user vs com.universalqr.admin):');

  // Android Application IDs & Namespaces
  final userAndroidGradle = File('${userAppDir.path}/android/app/build.gradle.kts').readAsStringSync();
  final adminAndroidGradle = File('${adminAppDir.path}/android/app/build.gradle.kts').readAsStringSync();

  assertRule(
    'user_app Android applicationId is com.universalqr.user',
    userAndroidGradle.contains('applicationId = "com.universalqr.user"'),
    'Expected applicationId = "com.universalqr.user"',
  );
  assertRule(
    'user_app Android namespace is com.universalqr.user',
    userAndroidGradle.contains('namespace = "com.universalqr.user"'),
    'Expected namespace = "com.universalqr.user"',
  );
  assertRule(
    'admin_app Android applicationId is com.universalqr.admin',
    adminAndroidGradle.contains('applicationId = "com.universalqr.admin"'),
    'Expected applicationId = "com.universalqr.admin"',
  );
  assertRule(
    'admin_app Android namespace is com.universalqr.admin',
    adminAndroidGradle.contains('namespace = "com.universalqr.admin"'),
    'Expected namespace = "com.universalqr.admin"',
  );

  // iOS Bundle Identifiers
  final userIosPbx = File('${userAppDir.path}/ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  final adminIosPbx = File('${adminAppDir.path}/ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  assertRule(
    'user_app iOS bundle id is com.universalqr.user',
    userIosPbx.contains('PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user;'),
    'Missing PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user;',
  );
  assertRule(
    'admin_app iOS bundle id is com.universalqr.admin',
    adminIosPbx.contains('PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin;'),
    'Missing PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin;',
  );

  // macOS Bundle Identifiers
  final userMacAppInfo = File('${userAppDir.path}/macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync();
  final adminMacAppInfo = File('${adminAppDir.path}/macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync();

  assertRule(
    'user_app macOS bundle id is com.universalqr.user',
    userMacAppInfo.contains('PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user'),
    'Expected PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.user',
  );
  assertRule(
    'admin_app macOS bundle id is com.universalqr.admin',
    adminMacAppInfo.contains('PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin'),
    'Expected PRODUCT_BUNDLE_IDENTIFIER = com.universalqr.admin',
  );

  // Linux Application IDs
  final userLinuxCmake = File('${userAppDir.path}/linux/CMakeLists.txt').readAsStringSync();
  final adminLinuxCmake = File('${adminAppDir.path}/linux/CMakeLists.txt').readAsStringSync();

  assertRule(
    'user_app Linux applicationId is com.universalqr.user',
    userLinuxCmake.contains('set(APPLICATION_ID "com.universalqr.user")'),
    'Expected set(APPLICATION_ID "com.universalqr.user")',
  );
  assertRule(
    'admin_app Linux applicationId is com.universalqr.admin',
    adminLinuxCmake.contains('set(APPLICATION_ID "com.universalqr.admin")'),
    'Expected set(APPLICATION_ID "com.universalqr.admin")',
  );

  print('\n[3] Verifying Application Display Names:');

  // Android App Labels
  final userManifest = File('${userAppDir.path}/android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final adminManifest = File('${adminAppDir.path}/android/app/src/main/AndroidManifest.xml').readAsStringSync();

  assertRule(
    'user_app Android label is "Universal QR Scanner"',
    userManifest.contains('android:label="Universal QR Scanner"'),
    'Expected android:label="Universal QR Scanner"',
  );
  assertRule(
    'admin_app Android label is "Universal QR Admin"',
    adminManifest.contains('android:label="Universal QR Admin"'),
    'Expected android:label="Universal QR Admin"',
  );

  // iOS Display Names
  final userIosPlist = File('${userAppDir.path}/ios/Runner/Info.plist').readAsStringSync();
  final adminIosPlist = File('${adminAppDir.path}/ios/Runner/Info.plist').readAsStringSync();

  assertRule(
    'user_app iOS display name is "Universal QR Scanner"',
    userIosPlist.contains('<string>Universal QR Scanner</string>'),
    'Missing <string>Universal QR Scanner</string> in iOS Info.plist',
  );
  assertRule(
    'admin_app iOS display name is "Universal QR Admin"',
    adminIosPlist.contains('<string>Universal QR Admin</string>'),
    'Missing <string>Universal QR Admin</string> in iOS Info.plist',
  );

  // macOS Product Names
  assertRule(
    'user_app macOS product name is "Universal QR Scanner"',
    userMacAppInfo.contains('PRODUCT_NAME = Universal QR Scanner'),
    'Missing PRODUCT_NAME = Universal QR Scanner in AppInfo.xcconfig',
  );
  assertRule(
    'admin_app macOS product name is "Universal QR Admin"',
    adminMacAppInfo.contains('PRODUCT_NAME = Universal QR Admin'),
    'Missing PRODUCT_NAME = Universal QR Admin in AppInfo.xcconfig',
  );

  // Windows Window Titles & Resource Descriptions
  final userWinMain = File('${userAppDir.path}/windows/runner/main.cpp').readAsStringSync();
  final adminWinMain = File('${adminAppDir.path}/windows/runner/main.cpp').readAsStringSync();
  final userWinRc = File('${userAppDir.path}/windows/runner/Runner.rc').readAsStringSync();
  final adminWinRc = File('${adminAppDir.path}/windows/runner/Runner.rc').readAsStringSync();

  assertRule(
    'user_app Windows window title is "Universal QR Scanner"',
    userWinMain.contains('L"Universal QR Scanner"'),
    'Missing L"Universal QR Scanner" in main.cpp',
  );
  assertRule(
    'admin_app Windows window title is "Universal QR Admin"',
    adminWinMain.contains('L"Universal QR Admin"'),
    'Missing L"Universal QR Admin" in main.cpp',
  );
  assertRule(
    'user_app Windows resource product name is "Universal QR Scanner"',
    userWinRc.contains('VALUE "ProductName", "Universal QR Scanner"'),
    'Missing ProductName in Runner.rc',
  );
  assertRule(
    'admin_app Windows resource product name is "Universal QR Admin"',
    adminWinRc.contains('VALUE "ProductName", "Universal QR Admin"'),
    'Missing ProductName in Runner.rc',
  );

  // Linux Window Titles
  final userLinuxApp = File('${userAppDir.path}/linux/runner/my_application.cc').readAsStringSync();
  final adminLinuxApp = File('${adminAppDir.path}/linux/runner/my_application.cc').readAsStringSync();

  assertRule(
    'user_app Linux window title is "Universal QR Scanner"',
    userLinuxApp.contains('"Universal QR Scanner"'),
    'Missing "Universal QR Scanner" in my_application.cc',
  );
  assertRule(
    'admin_app Linux window title is "Universal QR Admin"',
    adminLinuxApp.contains('"Universal QR Admin"'),
    'Missing "Universal QR Admin" in my_application.cc',
  );

  print('\n[4] Verifying Device Permissions & Entitlements:');

  // Android Permissions
  assertRule(
    'user_app Android camera permission',
    userManifest.contains('android.permission.CAMERA'),
    'Missing android.permission.CAMERA',
  );
  assertRule(
    'user_app Android storage/media permissions',
    userManifest.contains('android.permission.READ_EXTERNAL_STORAGE') &&
        userManifest.contains('android.permission.READ_MEDIA_IMAGES'),
    'Missing READ_EXTERNAL_STORAGE or READ_MEDIA_IMAGES',
  );
  assertRule(
    'user_app Android network permission',
    userManifest.contains('android.permission.INTERNET'),
    'Missing android.permission.INTERNET',
  );

  assertRule(
    'admin_app Android camera permission',
    adminManifest.contains('android.permission.CAMERA'),
    'Missing android.permission.CAMERA',
  );
  assertRule(
    'admin_app Android storage/media export permissions',
    adminManifest.contains('android.permission.READ_EXTERNAL_STORAGE') &&
        adminManifest.contains('android.permission.WRITE_EXTERNAL_STORAGE'),
    'Missing storage export permissions',
  );

  // iOS Permissions
  assertRule(
    'user_app iOS NSCameraUsageDescription',
    userIosPlist.contains('<key>NSCameraUsageDescription</key>'),
    'Missing NSCameraUsageDescription in iOS Info.plist',
  );
  assertRule(
    'user_app iOS NSPhotoLibraryUsageDescription',
    userIosPlist.contains('<key>NSPhotoLibraryUsageDescription</key>'),
    'Missing NSPhotoLibraryUsageDescription in iOS Info.plist',
  );

  assertRule(
    'admin_app iOS NSCameraUsageDescription',
    adminIosPlist.contains('<key>NSCameraUsageDescription</key>'),
    'Missing NSCameraUsageDescription in iOS Info.plist',
  );
  assertRule(
    'admin_app iOS NSPhotoLibraryUsageDescription',
    adminIosPlist.contains('<key>NSPhotoLibraryUsageDescription</key>'),
    'Missing NSPhotoLibraryUsageDescription in iOS Info.plist',
  );

  // macOS Entitlements & Permissions
  final userMacReleaseEnt = File('${userAppDir.path}/macos/Runner/Release.entitlements').readAsStringSync();
  final adminMacReleaseEnt = File('${adminAppDir.path}/macos/Runner/Release.entitlements').readAsStringSync();
  final userMacPlist = File('${userAppDir.path}/macos/Runner/Info.plist').readAsStringSync();
  final adminMacPlist = File('${adminAppDir.path}/macos/Runner/Info.plist').readAsStringSync();

  assertRule(
    'user_app macOS NSCameraUsageDescription',
    userMacPlist.contains('<key>NSCameraUsageDescription</key>'),
    'Missing NSCameraUsageDescription in macOS Info.plist',
  );
  assertRule(
    'admin_app macOS NSCameraUsageDescription',
    adminMacPlist.contains('<key>NSCameraUsageDescription</key>'),
    'Missing NSCameraUsageDescription in macOS Info.plist',
  );
  assertRule(
    'user_app macOS camera entitlement',
    userMacReleaseEnt.contains('<key>com.apple.security.device.camera</key>'),
    'Missing camera entitlement in Release.entitlements',
  );
  assertRule(
    'user_app macOS network client entitlement',
    userMacReleaseEnt.contains('<key>com.apple.security.network.client</key>'),
    'Missing network client entitlement in Release.entitlements',
  );
  assertRule(
    'admin_app macOS camera entitlement',
    adminMacReleaseEnt.contains('<key>com.apple.security.device.camera</key>'),
    'Missing camera entitlement in Release.entitlements',
  );
  assertRule(
    'admin_app macOS network client entitlement',
    adminMacReleaseEnt.contains('<key>com.apple.security.network.client</key>'),
    'Missing network client entitlement in Release.entitlements',
  );

  print('\n-----------------------------------------------------------');
  print('Auditor Summary: $passCount passed, $failCount failed.');

  if (failCount > 0) {
    stderr.writeln('[FAILED] Native runner configurations have violations.');
    exit(1);
  }

  print('[SUCCESS] All native runner configurations strictly verified.');
  exit(0);
}
