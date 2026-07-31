import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyez/core/theme/app_colors.dart';
import 'package:eyez/core/services/supabase_service.dart';
import 'package:eyez/core/services/tmdb_service.dart';
import 'package:eyez/features/auth/presentation/screens/login_screen.dart';
import 'package:eyez/features/home/presentation/widgets/movie_details_sheet.dart';
import 'package:eyez/features/home/presentation/providers/interaction_providers.dart';
import 'package:eyez/features/profile/presentation/providers/my_list_providers.dart';
import 'package:eyez/features/profile/presentation/providers/profile_providers.dart';
import 'package:eyez/features/profile/presentation/providers/history_providers.dart';
import 'package:eyez/features/profile/presentation/screens/platform_channel_screen.dart';

import 'package:eyez/features/profile/presentation/providers/profile_tabs_provider.dart';

import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 54),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 13),
              _buildProfileInfo(profileData),
              const SizedBox(height: 13),
              const _ProfileStats(),
              const SizedBox(height: 13),
              const _ProfileTabs(),
              const SizedBox(height: 8),
              _buildTabContent(myList, likedMovies),
              const SizedBox(height: 10),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 32), // Balance for settings icon
        const Spacer(),
        const Text(
          'PROFIL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
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
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 15),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(AsyncValue<Map<String, dynamic>?> profileData) {
    return profileData.when(
      data: (data) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonFuchsia, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4DFF2E93), // AppColors.neonFuchsia.withValues(alpha: 0.3)
                  blurRadius: 5,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 27,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SupabaseService.currentUser?.userMetadata?['username'] ?? 'Alexis',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Text(
            '@alexis_cine', // Placeholder for now or actual metadata
            style: TextStyle(color: AppColors.neonCyan, fontSize: 8),
          ),
          const SizedBox(height: 4),
          Text(
            data?['bio'] ?? 'Passionné de films et séries\nÀ la recherche de la prochaine pépite 🎬',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 7),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(color: AppColors.neonCyan),
      error: (e, s) => const Text('Erreur chargement profil', style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildTabContent(AsyncValue<List<Map<String, dynamic>>> myList, AsyncValue<List<Map<String, dynamic>>> likedMovies) {
    final activeTab = ref.watch(profileTabProvider);
    if (activeTab == 0) {
      // Abonnements Tab (Followed Channels)
      final followedPlatforms = ref.watch(followedPlatformsProvider);
      return followedPlatforms.when(
        data: (platforms) {
          if (followedPlatforms.value == null || platforms.isEmpty) {
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
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              final platform = platforms[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlatformChannelScreen(platformName: platform)),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 47,
                      height: 47,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3300D2FF), // AppColors.neonCyan.withValues(alpha: 0.2)
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          platform.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      platform,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w500),
                    ),
                    const Text(
                      'Chaine',
                      style: TextStyle(color: Colors.white38, fontSize: 6),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
      );
    } else if (activeTab == 1) {
      // Collections Tab
      return _buildGrid(myList, 'Aucun film dans votre collection');
    } else if (activeTab == 2) {
      // Favoris Tab
      return _buildGrid(likedMovies, 'Aucun favori pour le moment');
    } else if (activeTab == 3) {
      // Historique Tab
      final history = ref.watch(historyProvider);
      return _buildHistoryGrid(history, 'Aucun historique récent');
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text('Aucun historique récent', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildHistoryGrid(AsyncValue<List<Map<String, dynamic>>> itemsAsync, String emptyMsg) {
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

class _ProfileStats extends ConsumerWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myList = ref.watch(myListProvider);
    final likedMovies = ref.watch(likedMoviesProvider);
    final followedPlatforms = ref.watch(followedPlatformsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(value: likedMovies.value?.length.toString() ?? '0', label: 'J\'aime'),
        _StatItem(value: followedPlatforms.value?.length.toString() ?? '0', label: 'Abonnements'),
        _StatItem(value: myList.value?.length.toString() ?? '0', label: 'Collections'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 7, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ProfileTabs extends ConsumerWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(profileTabProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TabItem(index: 0, icon: Icons.movie_outlined, label: 'Abonnements', isSelected: activeTab == 0),
        _TabItem(index: 1, icon: Icons.list_alt_outlined, label: 'Collections', isSelected: activeTab == 1),
        _TabItem(index: 2, icon: Icons.favorite_border, label: 'Favoris', isSelected: activeTab == 2),
        _TabItem(index: 3, icon: Icons.history, label: 'Historique', isSelected: activeTab == 3),
      ],
    );
  }
}

class _TabItem extends ConsumerWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;

  const _TabItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(profileTabProvider.notifier).state = index,
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.neonFuchsia : AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.neonFuchsia : AppColors.textSecondary,
              fontSize: 7,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 3),
          if (isSelected)
            Container(height: 1.5, width: 13, color: AppColors.neonFuchsia),
        ],
      ),
    );
  }
}
