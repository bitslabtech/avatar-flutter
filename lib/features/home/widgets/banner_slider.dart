/// Banner slider widget for home screen
/// Horizontal PageView with dot indicators
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../models/banner.dart' as models;

class BannerSlider extends StatefulWidget {
  final List<models.Banner> banners;

  const BannerSlider({
    super.key,
    required this.banners,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Start autoplay if there's more than 1 banner
    if (widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.banners.length) {
          nextPage = 0;
        }
        
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 220, // Increased height for hero feel
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final bool hasContent = (banner.title != null && banner.title!.isNotEmpty) ||
                  (banner.tag != null && banner.tag!.isNotEmpty) ||
                  (banner.description != null && banner.description!.isNotEmpty) ||
                  (banner.btnText != null && banner.btnText!.isNotEmpty);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0), // Added bottom padding for shadow
                // Wrap ClipRRect in Container for shadow
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Ensure shadow renders correctly
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(60, 64, 67, 0.3),
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: Offset(0, 1),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(60, 64, 67, 0.15),
                        blurRadius: 3,
                        spreadRadius: 1,
                        offset: Offset(0, 1),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTap: () {
                        if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
                          if (banner.linkUrl!.startsWith('/?category=')) {
                            final category = Uri.parse(banner.linkUrl!).queryParameters['category'];
                            if (category != null) {
                              context.pushNamed('category-products', pathParameters: {'name': category});
                            }
                          } else if (banner.linkUrl!.startsWith('/category/')) {
                             final category = banner.linkUrl!.split('/category/').last;
                             context.pushNamed('category-products', pathParameters: {'name': category});
                          } else {
                            context.push(banner.linkUrl!);
                          }
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          CachedNetworkImage(
                            imageUrl: banner.resolvedImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                          
                          // Gradient Overlay (Only if content exists)
                          if (hasContent)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.5), // Reduced darkness by ~25%
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          
                          // Text Content (Matching HTML)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Badge
                                if (banner.tag != null && banner.tag!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        banner.tag!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Title
                                if (banner.title != null && banner.title!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      banner.title!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                // Description
                                if (banner.description != null && banner.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      banner.description!,
                                      style: TextStyle(
                                        color: Colors.grey[200],
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                // Button
                                if (banner.btnText != null && banner.btnText!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      banner.btnText!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

