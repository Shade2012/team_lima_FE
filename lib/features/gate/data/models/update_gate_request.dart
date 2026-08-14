class UpdateGateRequest {
  final String? name;

  UpdateGateRequest({this.name});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null && name!.isNotEmpty) {
      map['name'] = name;
    }
    return map;
  }
}
