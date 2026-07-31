import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../shared/widgets/brand_icons.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../../../profile/presentation/screens/platform_channel_screen.dart';
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
                
                const _SectionTitle(title: 'Genres'),
                const SizedBox(height: 7),
                _buildGenres(ref),
                const SizedBox(height: 13),

                const _SectionTitle(title: 'Plateformes'),
                const SizedBox(height: 7),
                _buildPlatforms(context),
                const SizedBox(height: 13),

                const _SectionTitle(title: 'Tendances'),
                const SizedBox(height: 8),
                _buildTrendingGrid(context, filteredContent),
              ] else ...[
                _SectionTitle(title: 'Résultats pour "$searchQuery"'),
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
    return const Row(
      children: [
        Text(
          'EXPLORER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        Spacer(),
        Text(
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
      decoration: const InputDecoration(
        hintText: 'Rechercher un film, une série...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: Icon(Icons.tune),
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref, String selectedCategory) {
    const categories = ['Pour toi', 'Films', 'Séries', 'Animes', 'Musique'];
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
    final selectedGenreId = ref.watch(selectedGenreProvider);

    const genres = [
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
        children: genres.map((genre) {
          final id = genre['id'] as int;
          final isSelected = selectedGenreId == id;
          
          return GestureDetector(
            onTap: () {
              if (isSelected) {
                ref.read(selectedGenreProvider.notifier).state = null;
              } else {
                ref.read(selectedGenreProvider.notifier).state = id;
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: isSelected ? AppColors.neonCyan : Colors.white10),
              ),
              child: Text(
                genre['name'] as String,
                style: TextStyle(
                  color: isSelected ? AppColors.neonCyan : Colors.white70, 
                  fontSize: 8, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlatforms(BuildContext context) {
    const platforms = [
      'Netflix',
      'Amazon Prime Video',
      'Disney+',
      'Apple TV+',
      'Crunchyroll',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: platforms.map((p) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlatformChannelScreen(platformName: p),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                PlatformIcon(name: p, size: 10),
                const SizedBox(width: 5),
                Text(
                  p,
                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w500),
                ),
              ],
            ),
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
          final platform = movie['platform'] ?? 'Netflix';

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
                Text(
                  platform,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 6),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
    );
  }
}
