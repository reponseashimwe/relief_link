import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showThemeToggle = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Widget> finalActions = actions?.toList() ?? [];
    
    if (showThemeToggle) {
      finalActions.add(
        IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        ),
      );
    }

    return AppBar(
      title: Text(title),
      leading: leading,
      actions: finalActions,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 