class FavoriteModel {
  final String jobId;

  FavoriteModel({required this.jobId});

  factory FavoriteModel.fromMap(Map<String, dynamic> data) {
    return FavoriteModel(
      jobId: data['jobId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
    };
  }
}
