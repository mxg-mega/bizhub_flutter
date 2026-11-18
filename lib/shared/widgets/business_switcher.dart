import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';

class BusinessSwitcher extends ConsumerStatefulWidget {
  const BusinessSwitcher({super.key});

  @override
  ConsumerState<BusinessSwitcher> createState() => _BusinessSwitcherState();
}

class _BusinessSwitcherState extends ConsumerState<BusinessSwitcher> {
  String? _businessIdsKey;
  Future<Map<String, String>>? _businessNamesFuture;

  Future<Map<String, String>> _loadBusinessNames(
    final List<String> businessIds,
  ) async {
    final names = await Future.wait(
      businessIds.map((final id) async {
        return MapEntry(id, await AuthService.getBusinessNameFromFirestore(id));
      }),
    );
    return Map.fromEntries(
      names
          .where((final entry) => entry.value != null)
          .map((final entry) => MapEntry(entry.key, entry.value!)),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final activeBusiness = authState.activeBusiness;

    if (user == null || user.businessIds.isEmpty) {
      return Text(activeBusiness?.name ?? 'No Business');
    }

    final businessIdsKey = '${user.id}:${user.businessIds.join(',')}';
    if (_businessIdsKey != businessIdsKey) {
      _businessIdsKey = businessIdsKey;
      _businessNamesFuture = _loadBusinessNames(user.businessIds);
    }

    return FutureBuilder<Map<String, String>>(
      future: _businessNamesFuture,
      builder: (final context, final snapshot) {
        final businessNames = snapshot.data ?? const <String, String>{};
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          itemBuilder: (final context) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text('Loading businesses...'),
                ),
              ];
            }
            if (snapshot.hasError) {
              return const [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text('Unable to load business names'),
                ),
              ];
            }
            if (businessNames.isEmpty) {
              return const [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text('No businesses available'),
                ),
              ];
            }

            return businessNames.entries.map((final entry) {
              final isSelected = entry.key == activeBusiness?.id;
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 18, color: Colors.green),
                    if (isSelected) const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}
