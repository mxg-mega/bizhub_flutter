import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../dashboard/data/repositories/employee_repository_impl.dart';

class AcceptInvitePage extends ConsumerStatefulWidget {
  final String inviteId;
  const AcceptInvitePage({super.key, required this.inviteId});

  @override
  ConsumerState<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends ConsumerState<AcceptInvitePage> {
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleInvitation();
  }

  Future<void> _handleInvitation() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider);
      final employeeRepo = ref.read(employeeRepositoryProvider);

      // 1. Fetch Invitation Details
      final invitation = await employeeRepo.getInvitation(widget.inviteId);
      if (invitation == null) {
        setState(() => _error = 'Invitation not found or expired.');
        return;
      }

      // 2. Auth Check
      if (auth.user == null) {
        // Redirect to login but keep the invite ID
        if (mounted) {
          context.go('/login?inviteId=${widget.inviteId}&email=${invitation.to}');
        }
        return;
      }

      // 3. Email Verification
      if (auth.user!.email != invitation.to) {
        setState(() => _error = 'Email Mismatch: This invite was sent to ${invitation.to}, but you are logged in as ${auth.user!.email}.');
        return;
      }

      // 4. Accept Invitation (Transactional)
      await employeeRepo.acceptInvitation(widget.inviteId, auth.user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined ${invitation.businessName}!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                SizedBox(height: 24.h),
                Text('Joining workspace...', style: GoogleFonts.inter(fontSize: 16.sp)),
              ] else if (_error != null) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 24.h),
                Text(
                  'Oops!',
                  style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
}
