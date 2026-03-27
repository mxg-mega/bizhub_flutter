import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.onBack,
    this.scaffoldActions,
    this.appBar,
    this.hasAppBar = true,
    this.extendBodyBehindAppBar = false,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.removeBodyPadding = false,
    this.titleText,
    this.titleTextStyle,
  });

  final Widget body;
  final void Function()? onBack;
  final List<Widget>? scaffoldActions;
  final Widget? title;
  final PreferredSizeWidget? appBar;
  final bool hasAppBar;
  final bool extendBodyBehindAppBar;
  final Widget? bottomNavigationBar;
  final bool removeBodyPadding;
  final Widget? floatingActionButton;
  final String? titleText;
  final TextStyle? titleTextStyle;

  static const _surfaceRadius = Radius.circular(28);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    const surfaceColor = Colors.white60;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: hasAppBar
          ? (appBar ??
                (title != null || onBack != null || scaffoldActions != null
                    ? AppBar(
                        title:
                            title ??
                            Text(titleText ?? '', style: titleTextStyle),
                        toolbarHeight: 87.h,
                        centerTitle: true,
                        leading: onBack != null
                            ? IconButton(
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back),
                              )
                            : null,
                        backgroundColor: surfaceColor,
                        elevation: 0,
                        actions: scaffoldActions,
                      )
                    : null))
          : null,
      body: removeBodyPadding
          ? body
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: body,
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}
