// lib/shared/widgets/horizontal_card_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class HorizontalCardCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> cardData;
  final List<Color> cardColors;
  final Duration autoSlideInterval;
  final Function(int)? onPageChanged;

  const HorizontalCardCarousel({
    Key? key,
    required this.cardData,
    required this.cardColors,
    this.autoSlideInterval = const Duration(seconds: 5),
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<HorizontalCardCarousel> createState() => _HorizontalCardCarouselState();
}

class _HorizontalCardCarouselState extends State<HorizontalCardCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isAutoSliding = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(widget.autoSlideInterval, (timer) {
      if (_isAutoSliding && !_isDragging && mounted && widget.cardData.isNotEmpty) {
        if (_currentPage < widget.cardData.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _stopAutoSlide() {
    setState(() {
      _isAutoSliding = false;
    });
  }

  void _resumeAutoSlide() {
    setState(() {
      _isAutoSliding = true;
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollStartNotification) {
                setState(() {
                  _isDragging = true;
                });
                _stopAutoSlide();
              } else if (notification is ScrollEndNotification) {
                setState(() {
                  _isDragging = false;
                });
                _resumeAutoSlide();
                _startAutoSlide();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
                if (widget.onPageChanged != null) {
                  widget.onPageChanged!(page);
                }
              },
              itemCount: widget.cardData.length,
              itemBuilder: (context, index) {
                return _buildCard(
                  widget.cardData[index],
                  widget.cardColors[index % widget.cardColors.length],
                  index,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.cardData.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: _currentPage == index
                    ? LinearGradient(
                        colors: [
                          widget.cardColors[index % widget.cardColors.length],
                          widget.cardColors[index % widget.cardColors.length].withOpacity(0.6),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          context.secondaryText.withOpacity(0.3),
                          context.secondaryText.withOpacity(0.2),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Auto-slide controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: context.secondaryText.withOpacity(0.2),
              ),
              child: _isAutoSliding
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: widget.autoSlideInterval,
                          width: constraints.maxWidth * 
                              ((_currentPage + 1) / widget.cardData.length),
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: widget.cardColors[_currentPage % widget.cardColors.length],
                          ),
                        );
                      },
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isAutoSliding ? Icons.pause : Icons.play_arrow,
                  size: 16,
                  color: widget.cardColors[_currentPage % widget.cardColors.length],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    if (_isAutoSliding) {
                      _stopAutoSlide();
                    } else {
                      _resumeAutoSlide();
                      _startAutoSlide();
                    }
                  });
                },
                tooltip: _isAutoSliding ? 'Pause auto-slide' : 'Resume auto-slide',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> data, Color color, int index) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        _stopAutoSlide();
        if (data['onPressed'] != null) {
          data['onPressed'](context);
        }
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isDragging) {
            _resumeAutoSlide();
            _startAutoSlide();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.85),
                  theme.brightness == Brightness.dark 
                      ? Colors.grey.shade900.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with icon and page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          data['icon'],
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1}/${widget.cardData.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    data['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Expanded(
                    child: Text(
                      data['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (data['onPressed'] != null) {
                          data['onPressed'](context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        data['buttonText'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}