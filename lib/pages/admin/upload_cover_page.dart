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
      setState(() => filePath = result.files.single.path);
    }
  }

  Future<void> upload() async {
    final id = int.tryParse(idCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректный ID книги')),
      );
      return;
    }
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите изображение')),
      );
      return;
    }

    setState(() => loading = true);
    final api = ref.read(apiProvider);
    try {
      await api.uploadCover(id, filePath!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Обложка успешно загружена')),
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
      appBar: AppBar(title: const Text('Загрузка обложки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: idCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID книги',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: loading ? null : pickFile,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Выбрать изображение'),
                  ),
                  if (filePath != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(
                        filePath!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: loading ? null : upload,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(loading ? 'Загрузка...' : 'Загрузить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
