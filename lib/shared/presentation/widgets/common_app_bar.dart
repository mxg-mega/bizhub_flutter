import 'package:flutter/material.dart';
import '../../widgets/business_switcher.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final String? title;
  final bool showDrawer;
  final bool hasTitle;

  const CommonAppBar({
    super.key,
    this.actions,
    this.showDrawer = true, 
    this.hasTitle = false,
    this.title = '',
  });

  @override
  Widget build(final BuildContext context) => AppBar(
      title: hasTitle ? Text(title!) : const BusinessSwitcher(),
      actions: actions,
      leading: showDrawer ? null : const BackButton(),
      elevation: 0,
    );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
