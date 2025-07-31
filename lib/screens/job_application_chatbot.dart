import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application_state.dart';

class JobApplicationChatbot extends StatelessWidget {
  final Map<String, dynamic>? jobData;

  const JobApplicationChatbot({super.key, this.jobData});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Job Application Chatbot'),
            backgroundColor: Colors.blue[700],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return ListTile(
                      title: Text(message['text'] ?? ''),
                      tileColor: message['role'] == 'bot' ? Colors.grey[200] : Colors.white,
                      subtitle: Text(message['role'] == 'bot' ? 'Bot' : 'You'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                        decoration: InputDecoration(
                          hintText: state.isInitialized ? 'Type your message...' : 'Initializing...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        enabled: state.isInitialized,
                        onSubmitted: (value) => state.sendMessage(value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: state.isInitialized
                          ? () => state.sendMessage(TextEditingController().text)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}