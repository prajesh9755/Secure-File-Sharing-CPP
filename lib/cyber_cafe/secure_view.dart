import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SecureViewer extends StatelessWidget {
  final String url;
  final bool isPdf;

  const SecureViewer({super.key, required this.url, required this.isPdf});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Document Content
        Positioned.fill(
          child: isPdf
              ? SfPdfViewer.network(url)
              : InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
        ),

        // 2. Visual Security: Semi-transparent Watermark
        // This prevents clean screenshots/photos on PC
        IgnorePointer(
          child: Center(
            child: Opacity(
              opacity: 0.5,
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(-30 / 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      "CONFIDENTIAL - CYBER VIEW ONLY",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}