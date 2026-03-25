import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class CopyShareButtons extends StatelessWidget {
  final String contentToCopy;
  final String shareText;

  const CopyShareButtons({
    super.key,
    required this.contentToCopy,
    required this.shareText,
  });

  void _copyToClipboard(BuildContext context) {
    if (contentToCopy.isEmpty) return;
    Clipboard.setData(ClipboardData(text: contentToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareContent() {
    if (shareText.isEmpty) return;
    // ignore: deprecated_member_use
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy',
          onPressed: () => _copyToClipboard(context),
        ),
        IconButton(
          icon: const Icon(Icons.share, size: 20),
          tooltip: 'Share',
          onPressed: _shareContent,
        ),
      ],
    );
  }
}
