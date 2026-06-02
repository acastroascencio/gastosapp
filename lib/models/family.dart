class FamilyMember {
  final String userId;
  final String role; // 'admin' | 'member'
  final DateTime joinedAt;
  final String? fullName; // Dynamic UI resolver helper

  FamilyMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json, {String? userFullName}) {
    return FamilyMember(
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      fullName: userFullName ?? json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class Family {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final String adminUserId;
  final List<FamilyMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final String? deletedBy;
  final DateTime? deletedAt;

  Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.adminUserId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.deletedBy,
    this.deletedAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List<dynamic>? ?? [];
    List<FamilyMember> parsedMembers = rawMembers
        .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      adminUserId: json['admin_user_id'] as String,
      members: parsedMembers,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deleted: json['deleted'] as bool? ?? false,
      deletedBy: json['deleted_by'] as String?,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'admin_user_id': adminUserId,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted': deleted,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Family copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    String? adminUserId,
    List<FamilyMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    String? deletedBy,
    DateTime? deletedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      adminUserId: adminUserId ?? this.adminUserId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
