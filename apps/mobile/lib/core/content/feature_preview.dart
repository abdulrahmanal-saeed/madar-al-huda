import 'package:flutter/foundation.dart';

const featurePreviewEnabled =
    kDebugMode || bool.fromEnvironment('MADAR_FEATURE_PREVIEW');

// Dev installs can read the verified Mushaf and content published by the owner.
const managedReleaseEnabled =
    featurePreviewEnabled || bool.fromEnvironment('MADAR_MANAGED_RELEASE');
