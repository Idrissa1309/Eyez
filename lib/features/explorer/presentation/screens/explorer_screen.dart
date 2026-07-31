import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../providers/explorer_providers.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

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
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredContent = ref.watch(filteredContentProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 54),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildSearchBar(ref),
              const SizedBox(height: 8),
              
              if (searchQuery.isEmpty) ...[
                _buildCategories(ref, selectedCategory),
                const SizedBox(height: 10),
                
                _buildSectionTitle('Genres'),
                const SizedBox(height: 7),
                _buildGenres(ref),
                const SizedBox(height: 13),

                _buildSectionTitle('Plateformes'),
                const SizedBox(height: 7),
                _buildPlatforms(context),
                const SizedBox(height: 13),

                _buildSectionTitle('Tendances'),
                const SizedBox(height: 8),
                _buildTrendingGrid(context, filteredContent),
              ] else ...[
                _buildSectionTitle('Résultats pour "$searchQuery"'),
                const SizedBox(height: 8),
                _buildSearchResults(context, searchResults),
              ],
            ],
          ),
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        const Text(
          'Découvrir du contenu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 7),
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return TextField(
      focusNode: _searchFocusNode,
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
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
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

  Widget _buildGenres(WidgetRef ref) {
    final genres = [
      {'id': 28, 'name': 'Action'},
      {'id': 12, 'name': 'Aventure'},
      {'id': 16, 'name': 'Animation'},
      {'id': 35, 'name': 'Comédie'},
      {'id': 80, 'name': 'Crime'},
      {'id': 18, 'name': 'Drame'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: genres.map((genre) => Container(
          margin: const EdgeInsets.only(right: 7),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            genre['name'] as String,
            style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w500),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPlatforms(BuildContext context) {
    final platforms = [
      {'name': 'Netflix', 'color': Colors.red},
      {'name': 'Amazon Prime Video', 'color': Colors.blue},
      {'name': 'Apple TV+', 'color': Colors.white},
      {'name': 'Disney+', 'color': Colors.indigo},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: platforms.map((p) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: p['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (p['name'] as String).substring(0, 1),
                    style: const TextStyle(color: Colors.black, fontSize: 6, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                p['name'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTrendingGrid(BuildContext context, AsyncValue<List<dynamic>> trending) {
    return trending.when(
      data: (items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 15,
          childAspectRatio: 0.65,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final movie = items[index];
          final posterPath = movie['poster_path'];
          final rating = movie['vote_average']?.toStringAsFixed(1) ?? 'N/A';
          final title = movie['title'] ?? movie['name'] ?? '';

          return GestureDetector(
            onTap: () => _showMovieDetails(context, movie),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surface,
                          image: posterPath != null ? DecorationImage(
                            image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$posterPath'),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 7),
                              const SizedBox(width: 2),
                              Text(
                                rating,
                                style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildCategory(String title, {required VoidCallback onTap, bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonFuchsia.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected ? AppColors.neonFuchsia : AppColors.outline,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
