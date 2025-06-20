class UserResponse {
  final String username;
  final String password;

  UserResponse({required this.username, required this.password});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      username: json['name'] ?? '',
      password: json['email'] ?? '',
    );
  }
}
