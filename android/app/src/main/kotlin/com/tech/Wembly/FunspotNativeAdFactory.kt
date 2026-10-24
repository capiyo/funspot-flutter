package com.tech.Funzy

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class FunspotNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val view = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        val headline = view.findViewById<TextView>(R.id.ad_headline)
        val media = view.findViewById<MediaView>(R.id.ad_media)
        val body = view.findViewById<TextView>(R.id.ad_body)
        val callToAction = view.findViewById<Button>(R.id.ad_call_to_action)
        val icon = view.findViewById<ImageView>(R.id.ad_app_icon)
        val stars = view.findViewById<RatingBar>(R.id.ad_stars)
        val advertiser = view.findViewById<TextView>(R.id.ad_advertiser)
        val store = view.findViewById<TextView>(R.id.ad_store)
        val price = view.findViewById<TextView>(R.id.ad_price)

        view.headlineView = headline
        view.mediaView = media
        view.bodyView = body
        view.callToActionView = callToAction
        view.iconView = icon
        view.starRatingView = stars
        view.advertiserView = advertiser
        view.storeView = store
        view.priceView = price

        headline.text = nativeAd.headline
        nativeAd.body?.let {
            body.text = it
            body.visibility = View.VISIBLE
        }
        nativeAd.callToAction?.let {
            callToAction.text = it
            callToAction.visibility = View.VISIBLE
        }
        nativeAd.icon?.let {
            icon.setImageDrawable(it.drawable)
            icon.visibility = View.VISIBLE
        }
        nativeAd.starRating?.let {
            stars.rating = it.toFloat()
            stars.visibility = View.VISIBLE
        }
        nativeAd.advertiser?.let {
            advertiser.text = it
            advertiser.visibility = View.VISIBLE
        }
        nativeAd.store?.let {
            store.text = it
            store.visibility = View.VISIBLE
        }
        nativeAd.price?.let {
            price.text = it
            price.visibility = View.VISIBLE
        }

        view.setNativeAd(nativeAd)
        return view
    }
}
