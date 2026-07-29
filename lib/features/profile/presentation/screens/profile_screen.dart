import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../providers/my_list_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/profile_video_providers.dart';

import 'settings_screen.dart';
import 'profile_video_player_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTab = 0; // 0: Abonnements, 1: Collections, 2: Favoris, 3: Historique

  void _showMovieDetails(BuildContext context, dynamic movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MovieDetailsSheet(movie: movie),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myList = ref.watch(myListProvider);
    final profileData = ref.watch(profileDataProvider);
    final likedMovies = ref.watch(likedMoviesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildProfileInfo(profileData),
            const SizedBox(height: 30),
            _buildStats(myList, likedMovies),
            const SizedBox(height: 30),
            _buildTabs(),
            const SizedBox(height: 20),
            _buildTabContent(myList, likedMovies),
            const SizedBox(height: 40),
            _buildSettingsButton(),
            const SizedBox(height: 20),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          'PROFIL',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(AsyncValue<Map<String, dynamic>?> profileData) {
    return profileData.when(
      data: (data) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonFuchsia, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonFuchsia.withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            SupabaseService.currentUser?.userMetadata?['username'] ?? 'Alexis',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${SupabaseService.currentUser?.userMetadata?['username'] ?? 'alexis_cine'}',
            style: const TextStyle(color: AppColors.neonCyan, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            data?['bio'] ?? 'Passionné de films et séries\nÀ la recherche de la prochaine pépite 🎬',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(color: AppColors.neonCyan),
      error: (e, s) => const Text('Erreur chargement profil', style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildStats(AsyncValue<List<Map<String, dynamic>>> myList, AsyncValue<List<Map<String, dynamic>>> likedMovies) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('128', 'Abonnements'),
        _buildStat('842', 'Abonnés'),
        _buildStat(likedMovies.value?.length.toString() ?? '0', 'J\'aime'),
        _buildStat(myList.value?.length.toString() ?? '0', 'Collections'),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab(0, Icons.movie_outlined, 'Abonnements'),
        _buildTab(1, Icons.list_alt_outlined, 'Collections'),
        _buildTab(2, Icons.favorite_border, 'Favoris'),
        _buildTab(3, Icons.history, 'Historique'),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Column(
        children: [
          Icon(
            icon, 
            color: isSelected ? AppColors.neonFuchsia : AppColors.textSecondary, 
            size: 24
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.neonFuchsia : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(height: 2, width: 20, color: AppColors.neonFuchsia),
        ],
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<List<Map<String, dynamic>>> myList, AsyncValue<List<Map<String, dynamic>>> likedMovies) {
    if (_activeTab == 0) {
      // Abonnements Tab
      final profileVideos = ref.watch(profileVideosProvider);
      return profileVideos.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Aucun abonnement disponible', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileVideoPlayerScreen(movie: video)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.surface,
                    image: video['poster_path'] != null ? DecorationImage(
                      image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}${video['poster_path']}'),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${(index + 1) * 2},${index}K',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
      );
    } else if (_activeTab == 1) {
      // Collections Tab
      return _buildGrid(myList, 'Aucun film dans votre collection');
    } else if (_activeTab == 2) {
      // Favoris Tab
      return _buildGrid(likedMovies, 'Aucun favori pour le moment');
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text('Aucun historique récent', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildGrid(AsyncValue<List<Map<String, dynamic>>> itemsAsync, String emptyMsg) {
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(emptyMsg, style: const TextStyle(color: AppColors.textSecondary)),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final movie = {
              'id': item['tmdb_id'],
              'title': item['title'],
              'poster_path': item['poster_path'],
            };
            return GestureDetector(
              onTap: () => _showMovieDetails(context, movie),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surface,
                  image: item['poster_path'] != null ? DecorationImage(
                    image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}${item['poster_path']}'),
                    fit: BoxFit.cover,
                  ) : null,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            SizedBox(width: 15),
            Text('Paramètres', style: TextStyle(color: Colors.white)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () async {
        final navigator = Navigator.of(context);
        await SupabaseService.signOut();
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
      child: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent)),
    );
  }
}
