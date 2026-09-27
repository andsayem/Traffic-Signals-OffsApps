/// A reusable, production-ready AdMob layer for Flutter apps.
///
/// Import this single file - internal files under `src`-style folders are
/// not meant to be imported directly:
///
/// ```dart
/// import 'package:admob_kit/admob_kit.dart';
/// ```
library;

export 'config/admob_config.dart';
export 'config/admob_settings.dart';

export 'core/admob_logger.dart';
export 'core/admob_service.dart';
export 'core/admob_utils.dart' show AdMobUtils, FullScreenAdGuard;

export 'models/ad_result.dart';
export 'models/ad_type.dart';

export 'managers/ad_manager.dart';
export 'managers/app_open_ad_manager.dart';
export 'managers/banner_ad_manager.dart';
export 'managers/interstitial_ad_manager.dart';
export 'managers/native_ad_manager.dart';
export 'managers/rewarded_ad_manager.dart';
export 'managers/rewarded_interstitial_ad_manager.dart';

export 'widgets/ad_banner.dart';
export 'widgets/adaptive_banner_ad.dart';
export 'widgets/native_ad.dart';
