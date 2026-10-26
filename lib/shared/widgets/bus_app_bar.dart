import 'package:flutter/material.dart';

/// 沿用原本藍色漸層，首頁搜尋列與明細共用相同樣式。
class BusAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BusAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: title,
        actions: actions,
        flexibleSpace: Container(
            decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.cyanAccent.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )),
      );
}
