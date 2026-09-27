// Copy this file into your app's ios/Runner/ directory.
//
// Renders a loaded google_mobile_ads NativeAd as a plain UIKit view. Edit
// the layout inside `createNativeAd` to change the native ad's design -
// this class and the Dart `AdNative` widget never need to change for a
// pure layout tweak. For a more complex design, replace the programmatic
// layout below with a XIB-backed view.

import google_mobile_ads

class NativeAdFactoryExample: FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {
        let adView = GADNativeAdView(frame: .zero)

        let headline = UILabel()
        headline.font = .boldSystemFont(ofSize: 16)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        let body = UILabel()
        body.font = .systemFont(ofSize: 13)
        body.numberOfLines = 2
        body.text = nativeAd.body
        body.isHidden = nativeAd.body == nil
        adView.bodyView = body

        let icon = UIImageView(image: nativeAd.icon?.image)
        icon.isHidden = nativeAd.icon == nil
        adView.iconView = icon

        let cta = UIButton(type: .system)
        cta.setTitle(nativeAd.callToAction, for: .normal)
        cta.isUserInteractionEnabled = false
        cta.isHidden = nativeAd.callToAction == nil
        adView.callToActionView = cta

        let stack = UIStackView(arrangedSubviews: [icon, headline, body, cta])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}

// ---------------------------------------------------------------------
// Registration - add to ios/Runner/AppDelegate.swift:
//
// import google_mobile_ads
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     let factory = NativeAdFactoryExample()
//     FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
//       self,
//       factoryId: "adFactoryExample", // must match AdMobConfig.nativeAdFactoryId
//       nativeAdFactory: factory
//     )
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
// ---------------------------------------------------------------------
