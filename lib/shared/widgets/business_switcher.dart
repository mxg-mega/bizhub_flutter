import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class BusinessSwitcher extends ConsumerWidget {
  const BusinessSwitcher({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final activeBusiness = authState.activeBusiness;

    if (user == null || user.businessIds.isEmpty) {
      return Text(activeBusiness?.name ?? 'No Business');
    }

    return PopupMenuButton<String>(
      onSelected: (final businessId) {
        ref.read(authProvider.notifier).switchBusiness(businessId);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              activeBusiness?.name ?? 'Select Business',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      itemBuilder: (final context) {
        return user.businessIds.map((final id) {
          final isSelected = id == activeBusiness?.id;
          return PopupMenuItem<String>(
            value: id,
            child: Row(
              children: [
                if (isSelected) const Icon(Icons.check, size: 18, color: Colors.green),
                if (isSelected) const SizedBox(width: 8),
                Text('Business ID: $id'),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
