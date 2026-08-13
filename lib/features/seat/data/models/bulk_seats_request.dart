class BulkSeatsRequest {
  final String categoryId;
  final String prefix;

  BulkSeatsRequest({
    required this.categoryId,
    required this.prefix,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'prefix': prefix,
    };
  }
}
