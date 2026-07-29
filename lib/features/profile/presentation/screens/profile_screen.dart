import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../providers/my_list_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTab = 0; // 0: Vidéos, 1: Listes, 2: Favoris, 3: Historique

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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildProfileInfo(),
            const SizedBox(height: 30),
            _buildStats(),
            const SizedBox(height: 30),
            _buildTabs(),
            const SizedBox(height: 20),
            _buildTabContent(myList),
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
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
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
        const Text(
          'Passionné de films et séries\nÀ la recherche de la prochaine pépite 🎬',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('128', 'Abonnements'),
        _buildStat('842', 'Abonnés'),
        _buildStat('2,3K', 'J\'aime'),
        _buildStat('56', 'Listes'),
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
        _buildTab(0, Icons.movie_outlined, 'Vidéos'),
        _buildTab(1, Icons.list_alt_outlined, 'Listes'),
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
          Icon(icon, color: isSelected ? AppColors.neonFuchsia : AppColors.textSecondary, size: 24),
          const SizedBox(height: 4),
          if (isSelected)
            Container(height: 2, width: 20, color: AppColors.neonFuchsia),
        ],
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<List<Map<String, dynamic>>> myList) {
    if (_activeTab == 1) {
      // Listes Tab
      return myList.when(
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Aucun film dans votre liste', style: TextStyle(color: AppColors.textSecondary)),
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
              // Transform saved_lists map to TMDB movie format for the sheet
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

    // Default Grid (Vidéos, Favoris, etc. - currently static)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1485846234645-a62644f84728?q=80&w=1159&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return Container(
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
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () async {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent)),
    );
  }
}
