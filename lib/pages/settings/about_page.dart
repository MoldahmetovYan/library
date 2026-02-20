import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О BookHub')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BookHub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Приложение для чтения и управления библиотекой. '
              'Скоро здесь появится больше информации о команде и контактах.',
            ),
            SizedBox(height: 24),
            Text('Связаться с нами: support@bookhub.app'),
          ],
        ),
      ),
    );
  }
}
