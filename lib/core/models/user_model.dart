import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final int age;
  final String religionId;
  final List<String> selectedTextIds;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String tier;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.religionId,
    required this.selectedTextIds,
    required this.createdAt,
    required this.lastActiveAt,
    this.tier = 'free',
    this.photoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      age: data['age'] as int,
      religionId: data['religionId'] as String,
      selectedTextIds: List<String>.from(data['selectedTextIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      tier: (data['tier'] as String?) ?? 'free',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'religionId': religionId,
      'selectedTextIds': selectedTextIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'tier': tier,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    int? age,
    String? religionId,
    List<String>? selectedTextIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? tier,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      religionId: religionId ?? this.religionId,
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      tier: tier ?? this.tier,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
