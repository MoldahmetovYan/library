import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../constants.dart';
import '../../ui/app_backdrop.dart';

class RealtimePage extends StatefulWidget {
  const RealtimePage({super.key});

  @override
  State<RealtimePage> createState() => _RealtimePageState();
}

class _RealtimePageState extends State<RealtimePage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final List<String> _messages = <String>[];
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _connected = false;

  String get _wsUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port/ws/realtime';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _addMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, text);
      if (_messages.length > 100) {
        _messages.removeLast();
      }
    });
  }

  void _connect() {
    if (_connected) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _subscription = channel.stream.listen(
        (event) => _addMessage('<= $event'),
        onError: (error) {
          _addMessage('! error: $error');
          setState(() => _connected = false);
        },
        onDone: () {
          _addMessage('! disconnected');
          if (mounted) {
            setState(() => _connected = false);
          }
        },
      );
      _channel = channel;
      setState(() => _connected = true);
      _addMessage('connected to $_wsUrl');
    } catch (error) {
      _addMessage('! connect failed: $error');
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    if (mounted) {
      setState(() => _connected = false);
    }
  }

  void _send(String text) {
    if (!_connected || _channel == null) {
      _addMessage('! not connected');
      return;
    }
    _channel!.sink.add(text);
    _addMessage('=> $text');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Realtime WebSocket')),
      body: AppBackdrop(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _connected ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connected ? 'Connected' : 'Disconnected',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _connected ? null : _connect,
                            child: const Text('Connect'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _connected ? _disconnect : null,
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _messageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _send(_messageCtrl.text.trim()),
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Send'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _send('ping'),
                              icon: const Icon(Icons.wifi_tethering_rounded),
                              label: const Text('Ping'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final text = _messages[index];
                            final inbound = text.startsWith('<=');
                            final outbound = text.startsWith('=>');
                            return Align(
                              alignment: inbound
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: inbound
                                      ? scheme.secondaryContainer
                                      : outbound
                                      ? scheme.primaryContainer
                                      : scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(text),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
