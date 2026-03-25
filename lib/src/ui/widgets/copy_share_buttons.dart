import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class CopyShareButtons extends StatelessWidget {
  final String contentToCopy;
  final String shareText;
  final bool isIOS;

  const CopyShareButtons({
    super.key,
    required this.contentToCopy,
    required this.shareText,
    required this.isIOS,
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
    if (isIOS) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => _copyToClipboard(context),
            child: const Icon(CupertinoIcons.doc_on_doc, size: 20),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: _shareContent,
            child: const Icon(CupertinoIcons.share, size: 20),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          tooltip: 'Copy',
          onPressed: () => _copyToClipboard(context),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, size: 20),
          tooltip: 'Share',
          onPressed: _shareContent,
        ),
      ],
    );
  }
}
