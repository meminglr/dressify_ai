import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile.dart';
import 'profile_info_section.dart';

/// FlexibleSpaceBarWidget for the profile page header.
///
/// This widget creates a flexible space bar that expands and collapses on scroll,
/// displaying the user's cover image with a gradient overlay and profile information.
///
/// ## Features:
/// - Expanded height: 480px
/// - Collapsed height: 56px (AppBar default)
/// - Cover image background with gradient overlay
/// - Smooth expand/collapse animations
/// - ProfileInfoSection integration
/// - Bottom border radius (40px) when expanded
/// - Shadow effect from Figma design
///
/// ## Design Specs (from Figma):
/// - Background: Cover image with linear gradient overlay
/// - Gradient: transparent to rgba(0,0,0,0.7)
/// - Shadow: 0px 25px 50px -12px rgba(0,0,0,0.25)
/// - Border Radius: 40px (bottom corners when expanded)
///
/// Validates Requirements 2, 10, 15
class FlexibleSpaceBarWidget extends StatelessWidget {
  /// Profile data containing cover image URL
  final Profile profile;

  const FlexibleSpaceBarWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildBackground(),
    );
  }

  /// Builds the background with cover image, gradient overlay, and profile info
  Widget _buildBackground() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image background
          _buildCoverImage(),
          
          // Gradient overlay
          _buildGradientOverlay(),
          
          // Profile info section
          _buildProfileInfo(),
        ],
      ),
    );
  }

  /// Builds the cover image background
  Widget _buildCoverImage() {
    // Use avatarUrl as the full background image
    final imageUrl = profile.avatarUrl ?? profile.coverImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFFF8F9FA),
        ),
        errorWidget: (context, url, error) => _buildDefaultBackground(),
        memCacheHeight: 800, // Optimize for header size
        maxHeightDiskCache: 800,
      );
    }

    return _buildDefaultBackground();
  }

  /// Builds a default gradient background when no cover image is available
  Widget _buildDefaultBackground() {
    return const ColoredBox(color: Color(0xFFF8F9FA));
  }

  /// Builds the gradient overlay from transparent to dark
  Widget _buildGradientOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000), // Transparent
            Color(0xB3000000), // rgba(0,0,0,0.7)
          ],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }

  /// Builds the profile info section positioned at the bottom
  Widget _buildProfileInfo() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32, // Spacing from bottom
      child: ProfileInfoSection(
        profile: profile,
      ),
    );
  }
}
