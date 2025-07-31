class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String jobPosition;
  final String location;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.jobPosition,
    required this.location,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      jobPosition: data['jobPosition'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'jobPosition': jobPosition,
      'location': location,
    };
  }
}
