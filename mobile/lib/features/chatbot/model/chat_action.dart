import '../../../core/data/product_record.dart';

enum ChatActionState { pending, saving, success, failure, cancelled }

class ChatAction {
  ChatAction({required this.id, required this.kind, required this.arguments});
  final String id;
  final String kind;
  Map<String, dynamic> arguments;
  ChatActionState state = ChatActionState.pending;
  String? error;
  ProductRecord? product;
  List<ProductRecord> products = [];
  int subtotal = 0;
  int total = 0;
  int? change;
  bool get editable =>
      state == ChatActionState.pending || state == ChatActionState.failure;
}
