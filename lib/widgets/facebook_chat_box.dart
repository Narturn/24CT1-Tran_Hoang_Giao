import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class FacebookChatBox extends StatefulWidget {
  final UserModel friend;
  final VoidCallback onClose;

  const FacebookChatBox({
    super.key,
    required this.friend,
    required this.onClose,
  });

  @override
  State<FacebookChatBox> createState() => _FacebookChatBoxState();
}

class _FacebookChatBoxState extends State<FacebookChatBox> {
  final _db = DatabaseService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isMinimized = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await _db.sendMessage(
      recipientId: widget.friend.uid,
      text: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;

    return Container(
      width: 320,
      height: _isMinimized ? 46 : 420,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // slate-800
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isMinimized = !_isMinimized),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // slate-900
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blueAccent.shade700,
                        child: Text(
                          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      friend.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isMinimized ? Icons.keyboard_arrow_up : Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: _isMinimized ? 'Mở rộng' : 'Thu nhỏ',
                    onPressed: () => setState(() => _isMinimized = !_isMinimized),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Đóng chat',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),

          // Message area
          if (!_isMinimized) ...[
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.messagesStream(friend.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final messages = snapshot.data ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text(
                            'Gửi lời chào đến ${friend.name}!',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId'] == _db.uid;
                      final text = msg['text'] as String? ?? '';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 220),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF2563EB) : const Color(0xFF334155),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMe ? 14 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 14),
                            ),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Colors.grey.shade800, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent, size: 20),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
