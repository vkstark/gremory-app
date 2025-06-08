import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/logger.dart';

class UserService {
  final String baseUrl = "https://gremory-backend.onrender.com/api/v1";

  Future<User> createUser({
    String? username,
    String? email,
    String? displayName,
    String userType = 'registered',
    String? phoneNumber,
    String timezone = 'UTC',
    String languagePreference = 'en',
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_type': userType,
        'timezone': timezone,
        'language_preference': languagePreference,
      };

      // Add optional fields only if they are provided
      if (username != null && username.isNotEmpty) {
        requestBody['username'] = username;
      }
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (displayName != null && displayName.isNotEmpty) {
        requestBody['display_name'] = displayName;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }

      Logger.debug('Creating user with payload: ${jsonEncode(requestBody)}', 'UserService');

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Logger.debug('Create user response: ${response.statusCode} - ${response.body}', 'UserService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Handle the response structure based on your backend
        if (responseData['success'] == true && responseData['data'] != null) {
          return User.fromJson(responseData['data']);
        } else if (responseData['data'] != null) {
          return User.fromJson(responseData['data']);
        } else {
          // Fallback for direct user data
          return User.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to create user: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error creating user', 'UserService', e);
      throw Exception('Error creating user: $e');
    }
  }

  Future<User> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Handle different response structures
        // If it's wrapped in a response structure
        if (responseData.containsKey('data')) {
          return User.fromJson(responseData['data']);
        } else {
          // Direct user data
          return User.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to get user: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  Future<List<User>> getAllUsers({
    int page = 1,
    int perPage = 20,
    String? userType,
    String? status,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (userType != null) queryParams['user_type'] = userType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Handle the response structure based on your backend
        List<dynamic> usersData;
        if (responseData['success'] == true && responseData['users'] != null) {
          usersData = responseData['users'];
        } else if (responseData['users'] != null) {
          usersData = responseData['users'];
        } else if (responseData['data'] != null) {
          usersData = responseData['data'];
        } else {
          usersData = [];
        }
        
        return usersData.map((json) => User.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to get users: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting users: $e');
    }
  }

  Future<User> updateUserProfile({
    required int userId,
    String? username,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? timezone,
    String? languagePreference,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (displayName != null) updateData['display_name'] = displayName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (timezone != null) updateData['timezone'] = timezone;
      if (languagePreference != null) updateData['language_preference'] = languagePreference;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['data'] != null) {
          return User.fromJson(responseData['data']);
        } else {
          return User.fromJson(responseData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to update user: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to delete user: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<Map<String, dynamic>> seedTestUsers() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/seed-test-data'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to seed test users: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error seeding test users: $e');
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users-health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
