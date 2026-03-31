import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sandbox/mockable_states.dart';
import 'chat_screen.styles.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 依存注入によってCanvasSandboxからモックが流れる
    final state = context.watch<ChatState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final msg = state.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: msg.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!msg.isMe)
                        const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                size: 16, color: Colors.white)),
                      if (!msg.isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: msg.isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: msg.isMe
                                  ? ChatScreenStyles.myBubbleDecoration
                                  : ChatScreenStyles.otherBubbleDecoration,
                              child: Text(msg.text,
                                  style: msg.isMe
                                      ? ChatScreenStyles.myBubbleTextStyle
                                      : ChatScreenStyles.otherBubbleTextStyle),
                            ),
                            const SizedBox(height: 4),
                            Text(msg.timeStamp,
                                style: ChatScreenStyles.timeStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: ChatScreenStyles.inputPadding,
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Start a message',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEBEBEB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.send, color: Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
