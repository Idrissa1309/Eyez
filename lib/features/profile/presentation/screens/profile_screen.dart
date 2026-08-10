import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyez/core/theme/app_colors.dart';
import 'package:eyez/core/services/supabase_service.dart';
import 'package:eyez/core/services/tmdb_service.dart';
import 'package:eyez/features/home/presentation/widgets/movie_details_sheet.dart';
import 'package:eyez/features/home/presentation/providers/interaction_providers.dart';
import 'package:eyez/features/profile/presentation/providers/my_list_providers.dart';
import 'package:eyez/features/profile/presentation/providers/profile_providers.dart';
import 'package:eyez/features/profile/presentation/screens/platform_channel_screen.dart';
import 'package:eyez/features/profile/presentation/providers/profile_tabs_provider.dart';
import 'package:eyez/shared/widgets/brand_icons.dart';

import '../../../auth/presentation/screens/login_screen.dart';
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildProfileInfo(profileData),
                    const SizedBox(height: 30),
                    const _ProfileStats(),
                    const SizedBox(height: 30),
                    const _ProfileTabs(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            _buildSliverContent(myList, likedMovies),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              sliver: SliverToBoxAdapter(
                child: _buildLogoutButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 48), 
        const Spacer(),
        const Text(
          'PROFIL',
          style: TextStyle(
            fontSize: 18,
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
            SupabaseService.currentUser?.userMetadata?['username'] ?? 'Utilisateur',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${SupabaseService.currentUser?.userMetadata?['username']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'user'}',
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

  Widget _buildSliverContent(AsyncValue<List<Map<String, dynamic>>> myList, AsyncValue<List<Map<String, dynamic>>> likedMovies) {
    final activeTab = ref.watch(profileTabProvider);
    
    if (activeTab == 0) {
      final followedPlatforms = ref.watch(followedPlatformsProvider);
      return followedPlatforms.when(
        data: (platforms) {
          if (platforms.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('Aucun abonnement disponible', style: TextStyle(color: AppColors.textSecondary)))),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 25,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                        PlatformIcon(name: platform, size: 65, isCircular: true),
                        const SizedBox(height: 10),
                        Text(platform, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        const Text('Chaine', style: TextStyle(color: Colors.white38, fontSize: 9)),
                      ],
                    ),
                  );
                },
                childCount: platforms.length,
              ),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan))),
        error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)))),
      );
    } else if (activeTab == 1) {
      return _buildSliverGrid(myList, 'Aucun film dans votre collection');
    } else if (activeTab == 2) {
      return _buildSliverGrid(likedMovies, 'Aucun favori pour le moment');
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildSliverGrid(AsyncValue<List<Map<String, dynamic>>> itemsAsync, String emptyMsg) {
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text(emptyMsg, style: const TextStyle(color: AppColors.textSecondary)))),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                final movie = {
                  'id': item['tmdb_id'] ?? item['id'],
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
              childCount: items.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan))),
      error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)))),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            size: 24,
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
}
