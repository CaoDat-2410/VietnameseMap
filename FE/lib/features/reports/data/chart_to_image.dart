import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a chart widget into a base64 PNG.
///
/// The widget is briefly inserted into an [Overlay] via [OverlayEntry] so it
/// has access to a normal [BuildContext] (theme, MediaQuery, etc.) which
/// [fl_chart] and friends require. After the first frame settles we grab the
/// [RepaintBoundary.toImage] snapshot, encode it, and remove the overlay entry.
class ChartToImage {
  static Future<String?> renderToBase64({
    required BuildContext context,
    required Widget chart,
    Size size = const Size(640, 320),
    double pixelRatio = 2.0,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final repaintKey = GlobalKey();
    final completer = Completer<String?>();

    final entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: -10000,
          top: -10000,
          child: Material(
            color: Colors.transparent,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(),
                child: DefaultTextStyle(
                  style: const TextStyle(),
                  child: Theme(
                    data: Theme.of(context),
                    child: SizedBox.fromSize(
                      size: size,
                      child: RepaintBoundary(
                        key: repaintKey,
                        child: chart,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    void handleFrame(Duration _) {
      Timer(const Duration(milliseconds: 30), () async {
        try {
          final renderObject = repaintKey.currentContext?.findRenderObject();
          if (renderObject is RenderRepaintBoundary) {
            final image = await renderObject.toImage(pixelRatio: pixelRatio);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            final bytes = byteData?.buffer.asUint8List();
            if (bytes != null && bytes.isNotEmpty) {
              completer.complete(base64Encode(bytes));
            } else {
              completer.complete(null);
            }
          } else {
            completer.complete(null);
          }
        } catch (e) {
          completer.complete(null);
        } finally {
          entry.remove();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback(handleFrame);

    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      entry.remove();
      return null;
    });
  }
}