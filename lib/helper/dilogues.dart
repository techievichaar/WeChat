import 'package:flutter/material.dart';

class Dilogues {
  static void showSnacBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  static void showProgressBar(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) =>
            const Center(child: CircularProgressIndicator.adaptive()));
  }
}
