import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_provider.dart';
import '../../utils/error_mapper.dart';

class UploadCoverPage extends ConsumerStatefulWidget {
  const UploadCoverPage({super.key});

  @override
  ConsumerState<UploadCoverPage> createState() => _UploadCoverPageState();
}

class _UploadCoverPageState extends ConsumerState<UploadCoverPage> {
  late final TextEditingController idCtrl;
  String? filePath;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    idCtrl = TextEditingController();
  }

  @override
  void dispose() {
    idCtrl.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        filePath = result.files.single.path;
      });
    }
  }

  Future<void> upload() async {
    final id = int.tryParse(idCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid book ID')));
      return;
    }
    if (filePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a file first')));
      return;
    }

    setState(() => loading = true);
    final api = ref.read(apiProvider);
    try {
      await api.uploadCover(id, filePath!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover uploaded successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload cover')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: 'Book ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : pickFile,
              child: const Text('Select image'),
            ),
            if (filePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  filePath!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ElevatedButton(
              onPressed: loading ? null : upload,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
