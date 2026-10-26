import 'package:flutter/material.dart';
import 'package:bus_project/data/services/tdx_exception.dart';

String queryErrorMessage(Object error) =>
    error is TdxException ? error.message : '讀取資料失敗，請稍後重試。';

class QueryMessage extends StatelessWidget {
  const QueryMessage({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      );
}
