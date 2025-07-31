import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String contractType;
  final String description;
  final String createdBy;
  final Timestamp createdAt;
  final String status;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.contractType,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.status,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      contractType: data['contractType'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'contractType': contractType,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'status': status,
    };
  }
}
