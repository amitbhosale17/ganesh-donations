import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// A full-screen modal that lets the user pan/zoom an image and then
/// crops a 1:1 region from the visible area.
///
/// [isCircle] = true  → circle crop (portraits)
/// [isCircle] = false → rounded-square crop (logos)
///
/// Returns a [File] written to a temporary path, or null if cancelled.
///
/// FIX: The [RepaintBoundary] wraps the [InteractiveViewer] directly so that
/// [toImage()] captures the actual transformed (panned/zoomed) pixels, not a
/// separate static copy of the original.
class ImageCropDialog extends StatefulWidget {
  final String imagePath;
  final bool isCircle;

  const ImageCropDialog({super.key, required this.imagePath, this.isCircle = true});

  /// Open the dialog and return the cropped [File], or null if cancelled.
  static Future<File?> show(BuildContext context, String imagePath, {bool isCircle = true}) {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageCropDialog(imagePath: imagePath, isCircle: isCircle),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  // Key is on the RepaintBoundary that wraps the InteractiveViewer —
  // so toImage() captures exactly what the user sees after panning/zooming.
  final GlobalKey _repaintKey = GlobalKey();

  bool _cropping = false;

  Future<void> _crop() async {
    setState(() => _cropping = true);
    try {
      final RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

      // pixelRatio 3 gives a crisp 3× resolution output
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) Navigator.pop(context, null);
        return;
      }

      // path_provider gives a proper writable temp dir on Android/iOS/Desktop
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/portrait_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cropSize = MediaQuery.of(context).size.width * 0.82;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        _cropping ? null : () => Navigator.pop(context, null),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ),
                  const Text('Crop Photo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  TextButton(
                    onPressed: _cropping ? null : _crop,
                    child: _cropping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.orange))
                        : const Text('Use Photo',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ── Crop area ───────────────────────────────────────────────────
            // The RepaintBoundary wraps the ClipOval + InteractiveViewer so
            // that toImage() captures the user's actual pan/zoom state.
            Stack(
              alignment: Alignment.center,
              children: [
                // ① CAPTURE TARGET: clips to chosen shape and records whatever
                //   the user has panned/zoomed inside.
                RepaintBoundary(
                  key: _repaintKey,
                  child: widget.isCircle
                      ? ClipOval(
                          child: SizedBox(
                            width: cropSize,
                            height: cropSize,
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 6.0,
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                                width: cropSize,
                                height: cropSize,
                                cacheWidth: null,
                                gaplessPlayback: false,
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: cropSize,
                            height: cropSize,
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 6.0,
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                                width: cropSize,
                                height: cropSize,
                                cacheWidth: null,
                                gaplessPlayback: false,
                              ),
                            ),
                          ),
                        ),
                ),

                // ② Visual border guide (non-interactive, not captured)
                IgnorePointer(
                  child: Container(
                    width: cropSize,
                    height: cropSize,
                    decoration: BoxDecoration(
                      borderRadius: widget.isCircle
                          ? null
                          : BorderRadius.circular(16),
                      shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Text('Pinch & drag to adjust',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
