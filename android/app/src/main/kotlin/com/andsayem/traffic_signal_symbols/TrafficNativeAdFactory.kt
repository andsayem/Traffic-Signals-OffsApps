package com.andsayem.traffic_signal_symbols

// Binds a loaded NativeAd into res/layout/native_ad_layout.xml. Edit that
// layout (and the bindings below) to restyle the native ad; the Dart side
// never needs to change for a pure layout tweak.

import android.content.Context
import android.view.LayoutInflater
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

class TrafficNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        val headline = adView.findViewById<android.widget.TextView>(R.id.ad_headline)
        val body = adView.findViewById<android.widget.TextView>(R.id.ad_body)
        val icon = adView.findViewById<android.widget.ImageView>(R.id.ad_app_icon)
        val cta = adView.findViewById<android.widget.Button>(R.id.ad_call_to_action)

        headline.text = nativeAd.headline
        adView.headlineView = headline

        if (nativeAd.body != null) {
            body.text = nativeAd.body
            body.visibility = android.view.View.VISIBLE
        } else {
            body.visibility = android.view.View.INVISIBLE
        }
        adView.bodyView = body

        if (nativeAd.icon != null) {
            icon.setImageDrawable(nativeAd.icon!!.drawable)
            icon.visibility = android.view.View.VISIBLE
        } else {
            icon.visibility = android.view.View.GONE
        }
        adView.iconView = icon

        if (nativeAd.callToAction != null) {
            cta.text = nativeAd.callToAction
            cta.visibility = android.view.View.VISIBLE
        } else {
            cta.visibility = android.view.View.INVISIBLE
        }
        adView.callToActionView = cta

        adView.setNativeAd(nativeAd)
        return adView
    }
}

