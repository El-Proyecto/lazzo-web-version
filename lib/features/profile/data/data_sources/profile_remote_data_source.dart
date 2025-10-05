// Calls Supabase for profile operations

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final SupabaseClient client;

  ProfileRemoteDataSource(this.client);

  /// Fetch current user's profile
  Future<ProfileModel?> fetchCurrentUserProfile() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final response = await client
          .from('users')
          .select('id, name, email, avatar_url, city, birth_date')
          .eq('id', user.id)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch profile by user ID
  Future<ProfileModel?> fetchProfileById(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('id, name, email, avatar_url, city, birth_date')
          .eq('id', userId)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update current user's profile
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final response = await client
          .from('users')
          .update(profile.toMap())
          .eq('id', user.id)
          .select('id, name, email, avatar_url, city, birth_date')
          .single();

      return ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user's memories/events
  Future<List<MemoryModel>> fetchUserMemories(String userId) async {
    try {
      final response = await client
          .from('memories')
          .select('mem_id, mem_title, photo_id, mem_date, mem_location')
          .order('mem_location', ascending: false);

      return response.map((json) => MemoryModel.fromMap(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
