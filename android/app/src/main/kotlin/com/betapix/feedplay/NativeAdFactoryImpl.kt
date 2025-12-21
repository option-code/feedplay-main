package com.betapix.feedplay

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactoryImpl(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: Map<String, Any>?): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        with(nativeAdView) {
            // Set the media view.
            val mediaView = findViewById<com.google.android.gms.ads.nativead.MediaView>(R.id.ad_media)
            mediaView.setMediaContent(nativeAd.mediaContent)
            setMediaView(mediaView)

            // Set the headline and add the view to the view hierarchy.
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            headlineView.text = nativeAd.headline
            setHeadlineView(headlineView)

            // Set the body and add the view to the view hierarchy.
            val bodyView = findViewById<TextView>(R.id.ad_body)
            bodyView.text = nativeAd.body
            setBodyView(bodyView)

            // Set the call to action view and add the view to the view hierarchy.
            val callToActionView = findViewById<Button>(R.id.ad_call_to_action)
            callToActionView.text = nativeAd.callToAction
            setCallToActionView(callToActionView)

            // Set the app icon and add the view to the view hierarchy.
            val iconView = findViewById<ImageView>(R.id.ad_app_icon)
            if (nativeAd.icon == null) {
                iconView.visibility = View.GONE
            } else {
                iconView.setImageDrawable(nativeAd.icon?.drawable)
                iconView.visibility = View.VISIBLE
            }
            setIconView(iconView)

            // Set the advertiser view and add the view to the view hierarchy.
            val advertiserView = findViewById<TextView>(R.id.ad_advertiser)
            if (nativeAd.advertiser == null) {
                advertiserView.visibility = View.GONE
            } else {
                advertiserView.text = nativeAd.advertiser
                advertiserView.visibility = View.VISIBLE
            }
            setAdvertiserView(advertiserView)

            // Set the star rating view and add the view to the view hierarchy.
            val starRatingView = findViewById<RatingBar>(R.id.ad_stars)
            if (nativeAd.starRating == null) {
                starRatingView.visibility = View.GONE
            } else {
                starRatingView.rating = nativeAd.starRating!!.toFloat()
                starRatingView.visibility = View.VISIBLE
            }
            setStarRatingView(starRatingView)

            // The NativeAdView will render the NativeAd assets.
            nativeAdView.setNativeAd(nativeAd)
        }
        return nativeAdView
    }
}