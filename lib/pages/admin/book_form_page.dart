import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../providers/user_provider.dart';
import '../../utils/json_utils.dart';

class BookFormPage extends ConsumerStatefulWidget {
  const BookFormPage({super.key, this.book});

  final Book? book;

  @override
  ConsumerState<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends ConsumerState<BookFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleCtrl;
  late final TextEditingController authorCtrl;
  late final TextEditingController genreCtrl;
  late final TextEditingController descCtrl;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController();
    authorCtrl = TextEditingController();
    genreCtrl = TextEditingController();
    descCtrl = TextEditingController();

    final book = widget.book;
    if (book != null) {
      titleCtrl.text = book.title;
      authorCtrl.text = book.author;
      genreCtrl.text = book.genre ?? '';
      descCtrl.text = book.description ?? '';
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    authorCtrl.dispose();
    genreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> saveBook() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final payload = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'author': authorCtrl.text.trim(),
      'genre': genreCtrl.text.trim().isEmpty ? null : genreCtrl.text.trim(),
      'description':
          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    };

    setState(() => loading = true);
    final api = ref.read(apiProvider);
    try {
      if (widget.book == null) {
        await api.createBook(payload);
      } else {
        await api.updateBook(widget.book!.id, payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = _extractErrorMessage(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Update book' : 'Create book')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => _validateMinLength(value, 'Title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: authorCtrl,
              decoration: const InputDecoration(labelText: 'Author'),
              validator: (value) => _validateMinLength(value, 'Author'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: genreCtrl,
              decoration: const InputDecoration(labelText: 'Genre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveBook,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save changes' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateMinLength(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$fieldName is required';
    }
    if (text.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final map = extractMap(data);
        final message = map['message'] ?? map['error'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return 'Failed to save book';
  }
}
