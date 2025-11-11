import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../utils/app_theme.dart';
import '../utils/time_utils.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onChat,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.type == PostType.lost
                          ? AppTheme.lostColor
                          : AppTheme.foundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: post.type == PostType.lost
                              ? AppTheme.errorColor.withOpacity(0.2)
                              : AppTheme.successColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      post.getTypeLabel().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: post.type == PostType.lost
                            ? AppTheme.lostTextColor
                            : AppTheme.foundTextColor,
                      ),
                    ),
                  ),
                  // Date
                  Text(
                    TimeUtils.getTimeAgo(post.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.bgTertiary,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.bgTertiary,
                        child: const Center(
                          child: Icon(Icons.image, size: 50, color: AppTheme.textTertiary),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.bgTertiary,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgTertiary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            post.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stats (if any)
                  if (post.viewCount > 0 || post.messageCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          if (post.viewCount > 0) ...[
                            const Icon(Icons.visibility,
                                size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${post.viewCount} vistas',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                          if (post.viewCount > 0 && post.messageCount > 0)
                            const SizedBox(width: 16),
                          if (post.messageCount > 0) ...[
                            const Icon(Icons.chat,
                                size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${post.messageCount} mensajes',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            if (showActions)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.bgSecondary,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    if (onChat != null)
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat,
                          label: onEdit == null ? 'Contactar' : 'Editar',
                          onTap: onEdit ?? onChat!,
                          isPrimary: onEdit == null,
                        ),
                      ),
                    if (onChat != null && onTap != null)
                      const SizedBox(width: 8),
                    if (onTap != null)
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.visibility,
                          label: 'Ver más',
                          onTap: onTap!,
                          isPrimary: false,
                        ),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete,
                        label: '',
                        onTap: onDelete!,
                        isPrimary: false,
                        isDanger: true,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary
            ? AppTheme.primaryColor
            : (isDanger ? AppTheme.errorColor : AppTheme.bgTertiary),
        borderRadius: BorderRadius.circular(12),
        border: !isPrimary && !isDanger
            ? Border.all(color: AppTheme.borderMedium)
            : null,
        boxShadow: isPrimary || isDanger
            ? [
                BoxShadow(
                  color: (isPrimary
                          ? AppTheme.primaryColor
                          : AppTheme.errorColor)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary || isDanger
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPrimary || isDanger
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

