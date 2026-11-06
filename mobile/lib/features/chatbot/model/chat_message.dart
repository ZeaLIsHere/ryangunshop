/// Satu pesan pada percakapan chatbot.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;

  /// Benar bila pesan dikirim pengguna, salah bila balasan asisten.
  final bool isUser;
}
