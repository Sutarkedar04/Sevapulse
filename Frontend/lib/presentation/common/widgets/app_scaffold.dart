import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showAppBar;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: body,
    );
  }
}