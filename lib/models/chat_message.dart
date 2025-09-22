import 'user_profile.dart';

class ChatMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final String messageType;
  final String? attachmentUrl;
  final DateTime createdAt;
  final UserProfile? sender;

  ChatMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.messageType,
    this.attachmentUrl,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: json['sender'] != null
          ? UserProfile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isSystem => messageType == 'system';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}