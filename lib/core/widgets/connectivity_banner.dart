import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../utils/google_fonts.dart';

/// A global overlay banner that displays when the device loses network connectivity.
/// Place this as a child inside a Column or Stack at the top level of your Scaffold body.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);

    // Check initial state
    Connectivity().checkConnectivity().then((result) {
      final offline =
          result.isEmpty || result.contains(ConnectivityResult.none);
      if (offline && mounted) {
        setState(() => _isOffline = true);
        _animCtrl.forward();
      }
    });

    // Listen for changes
    _subscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final offline =
          result.isEmpty || result.contains(ConnectivityResult.none);
      if (offline != _isOffline && mounted) {
        setState(() => _isOffline = offline);
        if (offline) {
          _animCtrl.forward();
        } else {
          // Show "back online" briefly, then hide
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isOffline) _animCtrl.reverse();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isOffline
              ? AppTheme.warning.withValues(alpha: 0.95)
              : AppTheme.success.withValues(alpha: 0.95),
        ),
        child: Row(
          children: [
            Icon(
              _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isOffline
                    ? 'Anda sedang offline — data akan disinkronkan saat koneksi pulih'
                    : 'Koneksi pulih — menyinkronkan data...',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
