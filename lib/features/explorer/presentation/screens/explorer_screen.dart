import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../../../../shared/widgets/brand_icons.dart';
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
    final selectedGenre = ref.watch(selectedGenreProvider);
    final selectedPlatform = ref.watch(selectedPlatformProvider);
    final filteredContent = ref.watch(filteredContentProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSearchBar(ref),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          if (searchQuery.isEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Genres'),
                    const SizedBox(height: 15),
                    _buildGenres(ref, selectedGenre),
                    const SizedBox(height: 30),
                    
                    _buildSectionTitle('Plateformes'),
                    const SizedBox(height: 15),
                    _buildPlatforms(ref, selectedPlatform),
                    const SizedBox(height: 30),

                    _buildSectionTitle('Catégories'),
                    const SizedBox(height: 15),
                    _buildCategories(ref, selectedCategory),
                    const SizedBox(height: 30),
                    
                    _buildHeroSection(context, ref, filteredContent),
                    const SizedBox(height: 30),
                    _buildSectionTitle('Tendances'),
                    const SizedBox(height: 20),
                    _buildHorizontalList(context, filteredContent),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Résultats pour "$searchQuery"'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildSliverSearchResults(context, searchResults),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ],
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

  Widget _buildGenres(WidgetRef ref, int? selectedId) {
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
        children: genres.map((g) {
          final isSelected = selectedId == g['id'];
          return GestureDetector(
            onTap: () {
              ref.read(selectedGenreProvider.notifier).state = isSelected ? null : g['id'] as int;
              ref.read(selectedPlatformProvider.notifier).state = null;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.neonCyan : Colors.white10),
              ),
              child: Text(
                g['name'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlatforms(WidgetRef ref, String? selectedPlatform) {
    final platforms = ['Netflix', 'Amazon Prime Video', 'Disney+', 'Apple TV+', 'Crunchyroll'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: platforms.map((p) {
          final isSelected = selectedPlatform == p;
          return GestureDetector(
            onTap: () {
              ref.read(selectedPlatformProvider.notifier).state = isSelected ? null : p;
              ref.read(selectedGenreProvider.notifier).state = null;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white12 : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.white24 : Colors.white10),
              ),
              child: Row(
                children: [
                  PlatformIcon(name: p, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    p,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
          onTap: () {
            ref.read(selectedCategoryProvider.notifier).state = cat;
            ref.read(selectedGenreProvider.notifier).state = null;
            ref.read(selectedPlatformProvider.notifier).state = null;
          },
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
            height: 300,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              hero['release_date']?.split('-')[0] ?? '2024',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan))),
      error: (err, stack) => const SizedBox(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
    );
  }

  Widget _buildHorizontalList(BuildContext context, AsyncValue<List<dynamic>> items) {
    return SizedBox(
      height: 200,
      child: items.when(
        data: (list) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final movie = list[index];
            final posterPath = movie['poster_path'];
            final rating = movie['vote_average']?.toStringAsFixed(1) ?? '0.0';
            return GestureDetector(
              onTap: () => _showMovieDetails(context, movie),
              child: Container(
                width: 130,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.surface,
                  image: posterPath != null ? DecorationImage(
                    image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$posterPath'),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 3),
                            Text(rating, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, stack) => const SizedBox(),
      ),
    );
  }

  Widget _buildSliverSearchResults(BuildContext context, AsyncValue<List<dynamic>> results) {
    return results.when(
      data: (list) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            childCount: list.length,
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan))),
      error: (err, stack) => const SliverToBoxAdapter(child: Center(child: Icon(Icons.error_outline, color: Colors.red))),
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
