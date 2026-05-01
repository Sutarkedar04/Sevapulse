// lib/features/user/widgets/full_screen_image_page.dart
import 'package:flutter/material.dart';


class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const FullScreenImagePage({
    Key? key,
    required this.imageUrl,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title ?? 'Prescription Image'),
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Add share functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Add download functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Toggle app bar visibility on tap (close on tap)
          Navigator.pop(context);
        },
        onDoubleTap: () {
          // Close on double tap
          Navigator.pop(context);
        },
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading image...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.close,
                label: 'Close',
                onPressed: () => Navigator.pop(context),
                color: Colors.white,
              ),
              _buildActionButton(
                icon: Icons.zoom_in,
                label: 'Zoom',
                onPressed: () {},
                color: Colors.white,
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
          iconSize: 28,
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}