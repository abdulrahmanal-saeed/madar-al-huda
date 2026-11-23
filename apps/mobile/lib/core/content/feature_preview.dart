import 'package:flutter/foundation.dart';

const featurePreviewEnabled = bool.fromEnvironment(
  'MADAR_FEATURE_PREVIEW',
  defaultValue: kDebugMode,
);

// The signed Dev channel enables the reader, worship tools, and the published library.
const managedReleaseEnabled =
    featurePreviewEnabled || bool.fromEnvironment('MADAR_MANAGED_RELEASE');
