import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../providers/explorer_providers.dart';

class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  void _showMovieDetails(BuildContext context, dynamic movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MovieDetailsSheet(movie: movie),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredContent = ref.watch(filteredContentProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildSearchBar(ref),
            const SizedBox(height: 20),
            
            if (searchQuery.isEmpty) ...[
              _buildCategories(ref, selectedCategory),
              const SizedBox(height: 30),
              _buildHeroSection(context, ref, filteredContent),
              const SizedBox(height: 30),
              _buildSectionTitle('Contenu $selectedCategory'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, filteredContent),
            ] else ...[
              _buildSectionTitle('Résultats pour "$searchQuery"'),
              const SizedBox(height: 20),
              _buildSearchResults(context, searchResults),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'EXPLORER',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        const Text(
          'Découvrir du contenu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return TextField(
      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: 'Rechercher un film, une série...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.tune),
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref, String selectedCategory) {
    final categories = ['Pour toi', 'Films', 'Séries', 'Animes', 'Musique'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) => _buildCategory(
          cat, 
          isSelected: selectedCategory == cat,
          onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat,
        )).toList(),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> trending) {
    return trending.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox();
        final hero = items.first;
        final title = hero['title'] ?? hero['name'] ?? 'Inconnu';
        final backdropPath = hero['backdrop_path'];
        
        return GestureDetector(
          onTap: () => _showMovieDetails(context, hero),
          child: Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surface,
              image: backdropPath != null ? DecorationImage(
                image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$backdropPath'),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              hero['release_date']?.split('-')[0] ?? '2024',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 400, 
        width: double.infinity, 
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.surface),
        child: const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      ),
      error: (err, stack) => Container(
        height: 400, 
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.surface),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 15),
              const Text(
                'Problème de connexion TMDB',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Une erreur est survenue lors de la récupération des données.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => ref.invalidate(trendingProvider),
                icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
                label: const Text('Réessayer', style: TextStyle(color: AppColors.neonCyan)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildHorizontalList(BuildContext context, AsyncValue<List<dynamic>> items) {
    return SizedBox(
      height: 220,
      child: items.when(
        data: (list) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final movie = list[index];
            final posterPath = movie['poster_path'];
            return GestureDetector(
              onTap: () => _showMovieDetails(context, movie),
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.surface,
                  image: posterPath != null ? DecorationImage(
                    image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$posterPath'),
                    fit: BoxFit.cover,
                  ) : null,
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red, fontSize: 10)),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, AsyncValue<List<dynamic>> results) {
    return results.when(
      data: (list) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.7,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final posterPath = item['poster_path'];
          return GestureDetector(
            onTap: () => _showMovieDetails(context, item),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.surface,
                image: posterPath != null ? DecorationImage(
                  image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$posterPath'),
                  fit: BoxFit.cover,
                ) : null,
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, stack) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
    );
  }

  Widget _buildCategory(String title, {required VoidCallback onTap, bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonFuchsia.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.neonFuchsia : AppColors.outline,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
