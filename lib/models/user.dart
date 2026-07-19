class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImage;
  final String accountStatus; // pending, active, suspended
  final String approvalStatus; // pending, approved, rejected
  final DateTime createdAt;
  final SubscriptionDetails? subscription;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    required this.accountStatus,
    required this.approvalStatus,
    required this.createdAt,
    this.subscription,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImage: data['profileImage'],
      accountStatus: data['accountStatus'] ?? 'pending',
      approvalStatus: data['approvalStatus'] ?? 'pending',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      subscription: data['subscription'] != null
          ? SubscriptionDetails.fromMap(data['subscription'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'accountStatus': accountStatus,
      'approvalStatus': approvalStatus,
      'createdAt': createdAt,
      'subscription': subscription?.toMap(),
    };
  }
}

class SubscriptionDetails {
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, expired, cancelled

  SubscriptionDetails({
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory SubscriptionDetails.fromMap(Map<String, dynamic> data) {
    return SubscriptionDetails(
      planId: data['planId'] ?? '',
      planName: data['planName'] ?? '',
      startDate: data['startDate']?.toDate() ?? DateTime.now(),
      endDate: data['endDate']?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
    };
  }
}
