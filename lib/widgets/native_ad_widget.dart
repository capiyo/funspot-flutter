import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final String adUnitId;
  final double height;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    this.height = 100,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  Timer? _retryTimer;
  bool _isAdLoaded = false;

  bool get _adsSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_adsSupported) _loadNativeAd();
  }

  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId != widget.adUnitId && _adsSupported) {
      _retryTimer?.cancel();
      _nativeAd?.dispose();
      _nativeAd = null;
      _isAdLoaded = false;
      _loadNativeAd();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  void _loadNativeAd() {
    if (!mounted || !_adsSupported || widget.adUnitId.isEmpty) return;
    final ad = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      factoryId: 'defaultNative',
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _nativeAd = loadedAd as NativeAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (!mounted) return;
          _nativeAd = null;
          setState(() => _isAdLoaded = false);
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 30), () {
            if (mounted) _loadNativeAd();
          });
          debugPrint('AdMob native ad failed to load: $error');
        },
      ),
    );
    _nativeAd = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsSupported || widget.adUnitId.isEmpty) return const SizedBox.shrink();
    final ad = _nativeAd;
    if (!_isAdLoaded || ad == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Advertisement',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: AdWidget(ad: ad),
    );
  }
}
