import 'package:flutter/material.dart';
import '../../widgets/business_switcher.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showDrawer;

  const CommonAppBar({
    super.key,
    this.actions,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const BusinessSwitcher(),
      actions: actions,
      leading: showDrawer ? null : const BackButton(),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
