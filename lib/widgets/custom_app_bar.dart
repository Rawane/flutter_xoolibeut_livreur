import 'package:flutter/material.dart';
import '../theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? numeroLivreur;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.numeroLivreur,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      automaticallyImplyLeading: false,
      centerTitle: false,

      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            )
          : null,

      // ⭐ Correction de l'overflow
      title: Row(
        children: [
          // 🔥 Le titre prend l'espace disponible sans déborder
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleBoldWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ⭐ Numéro à droite
          if (numeroLivreur != null) ...[
            const SizedBox(width: 8),
            Text(
              numeroLivreur!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
