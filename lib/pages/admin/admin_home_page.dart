import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../providers/user_provider.dart';
import '../../utils/json_utils.dart';
import 'book_form_page.dart';
import 'upload_cover_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final List<Book> books = <Book>[];
  bool loading = false;
  bool error = false;
  bool _hasChanges = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    setState(() {
      loading = true;
      error = false;
    });
    final api = ref.read(apiProvider);
    try {
      final res = await api.getBooks();
      final list = extractList(res.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        books
          ..clear()
          ..addAll(list);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> deleteBook(Book book) async {
    final api = ref.read(apiProvider);
    try {
      await api.deleteBook(book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book "${book.title}" deleted')),
      );
      _hasChanges = true;
      await loadBooks();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete book')));
    }
  }

  Future<void> openForm({Book? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => BookFormPage(book: book)),
    );
    if (result == true) {
      _hasChanges = true;
      await loadBooks();
    }
  }

  Future<void> openUpload() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const UploadCoverPage()),
    );
    if (result == true) {
      _hasChanges = true;
      await loadBooks();
    }
  }

  void _close() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.pop(context, _hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _close,
          ),
          actions: [
            IconButton(
              onPressed: loading ? null : openUpload,
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Upload cover',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => openForm(),
          child: const Icon(Icons.add),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Failed to load books'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: loadBooks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadBooks,
                    child: books.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No books yet')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return ListTile(
                                title: Text(book.title),
                                subtitle: Text(book.author),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteBook(book),
                                ),
                                onTap: () => openForm(book: book),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
