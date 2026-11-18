import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/business_service.dart';
import '../../../../shared/models/module_state_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/constants/module_configs.dart';

class BusinessOnboardingPage extends ConsumerStatefulWidget {
  const BusinessOnboardingPage({super.key});

  @override
  ConsumerState<BusinessOnboardingPage> createState() =>
      _BusinessOnboardingPageState();
}

class _BusinessOnboardingPageState
    extends ConsumerState<BusinessOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Data
  String _businessName = '';
  String _industry = 'retail';
  String _businessSize = 'small';
  String _language = 'en';
  final List<String> _goals = [];
  final List<String> _selectedModules = ['inventory', 'pos', 'dashboard'];
  String _currency = 'NGN';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromExistingBusiness();
    });
  }

  void _initializeFromExistingBusiness() {
    final business = ref.read(currentBusinessProvider);
    if (business != null) {
      setState(() {
        _businessName = business.name ?? '';
        _industry = business.industry ?? 'retail';
        _businessSize = business.size ?? 'small';
        _language = business.language ?? 'en';

        if (business.goals.isNotEmpty) {
          _goals.clear();
          _goals.addAll(business.goals);
        }

        final modules = business.enabledModules;
        if (modules != null && modules is Map) {
          _selectedModules.clear();
          modules.forEach((final key, final value) {
            if (ModuleStateModel.isEnabled(value)) {
              _selectedModules.add(key.toString());
            }
          });
        }

        _currency =
            business.settings?['currency'] ??
            business.settings?['currencyCode'] ??
            'NGN';

        // Update the current step if we have a business name
        if (_businessName.isNotEmpty) {
          // If we have a name, we can skip to the second step
          _currentStep = 1;
        }
      });

      // Navigate to the correct page after state update
      if (_currentStep > 0) {
        _pageController.jumpToPage(_currentStep);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final onboardingData = OnboardingData(
      businessName: _businessName,
      industry: _industry,
      businessSize: _businessSize,
      locations: [], // Default to empty for now
      goals: _goals,
      selectedModules: _selectedModules,
      currency: _currency,
      language: _language,
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final business = ref.read(currentBusinessProvider);

      if (business != null && business.id != null) {
        await BusinessService().updateBusinessOnboarding(
          businessId: business.id!,
          data: onboardingData,
          ownerId: user.id,
        );
      } else {
        await BusinessService().createBusinessWithOnboarding(
          data: onboardingData,
          ownerId: user.id,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        await ref.read(authProvider.notifier).completeOnboarding();
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create business: $e')),
        );
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / _totalSteps,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppConfig.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (final index) =>
                    setState(() => _currentStep = index),
                children: [
                  _buildStep1Profile(),
                  _buildStep2Goals(),
                  _buildStep3Modules(),
                  _buildStep4Success(),
                ],
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Profile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_businessName.isNotEmpty) ...[
              Text(
                'Updating: $_businessName',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
            ],
            Text(
              'Tell us about your business',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This helps us customize BizMod for you',
              style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.grey),
            ),
            SizedBox(height: 32.h),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                border: OutlineInputBorder(),
              ),
              onChanged: (final val) => _businessName = val,
              validator: (final val) =>
                  (val == null || val.isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value:
                  [
                    'NGN',
                    'USD',
                    'EUR',
                    'GBP',
                    'KES',
                    'GHS',
                    'CAD',
                    'AUD',
                    'ZAR',
                    'INR',
                    'AED',
                  ].contains(_currency)
                  ? _currency
                  : 'NGN',
              decoration: const InputDecoration(
                labelText: 'Operational Currency *',
                prefixIcon: Icon(Icons.currency_exchange),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'NGN',
                  child: Text('NGN (₦) - Nigerian Naira'),
                ),
                DropdownMenuItem(
                  value: 'USD',
                  child: Text('USD (\$) - US Dollar'),
                ),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€) - Euro')),
                DropdownMenuItem(
                  value: 'GBP',
                  child: Text('GBP (£) - British Pound'),
                ),
                DropdownMenuItem(
                  value: 'KES',
                  child: Text('KES (KSh) - Kenyan Shilling'),
                ),
                DropdownMenuItem(
                  value: 'GHS',
                  child: Text('GHS (GH₵) - Ghanaian Cedi'),
                ),
                DropdownMenuItem(
                  value: 'CAD',
                  child: Text('CAD (CA\$) - Canadian Dollar'),
                ),
                DropdownMenuItem(
                  value: 'AUD',
                  child: Text('AUD (A\$) - Australian Dollar'),
                ),
                DropdownMenuItem(
                  value: 'ZAR',
                  child: Text('ZAR (R) - South African Rand'),
                ),
                DropdownMenuItem(
                  value: 'INR',
                  child: Text('INR (₹) - Indian Rupee'),
                ),
                DropdownMenuItem(value: 'AED', child: Text('AED - UAE Dirham')),
              ],
              onChanged: (final val) {
                if (val != null) setState(() => _currency = val);
              },
            ),
            SizedBox(height: 24.h),
            Text(
              'Industry Type *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildChoiceChip('retail', '🏪 Retail'),
                _buildChoiceChip('services', '💇 Services'),
                _buildChoiceChip('wholesale', '📦 Wholesale'),
                _buildChoiceChip('food', '🍔 Food'),
                _buildChoiceChip('other', '💼 Other'),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Business Size *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildSizeChip('solo', '👤 Just me'),
                _buildSizeChip('small', '👥 Small team'),
                _buildSizeChip('growing', '👨‍👩‍👧 Growing'),
                _buildSizeChip('established', '🏢 Established'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(final String id, final String label) {
    final isSelected = _industry == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (final bool val) {
        if (val) setState(() => _industry = id);
      },
    );
  }

  Widget _buildSizeChip(final String id, final String label) {
    final isSelected = _businessSize == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (final bool val) {
        if (val) setState(() => _businessSize = id);
      },
    );
  }

  Widget _buildStep2Goals() {
    final goalsList = [
      {
        'id': 'inventory',
        'label': 'Track inventory',
        'icon': Icons.inventory_2_outlined,
      },
      {'id': 'sales', 'label': 'Increase sales', 'icon': Icons.trending_up},
      {
        'id': 'finance',
        'label': 'Better finance',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {'id': 'crm', 'label': 'Manage CRM', 'icon': Icons.people_outline},
    ];

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your goals?',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              itemCount: goalsList.length,
              itemBuilder: (final context, final index) {
                final goal = goalsList[index];
                final id = goal['id'] as String;
                final isSelected = _goals.contains(id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _goals.remove(id);
                      } else {
                        _goals.add(id);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppConfig.primaryColor
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      color: isSelected
                          ? AppConfig.primaryColor.withOpacity(0.05)
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          goal['icon'] as IconData,
                          color: isSelected
                              ? AppConfig.primaryColor
                              : Colors.grey,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          goal['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Modules() {
    const allModules = ModuleConfigs.allModules;

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Modules',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          const Text(
            'Pick the tools you need to get started',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: ListView.builder(
              itemCount: allModules.length,
              itemBuilder: (final context, final index) {
                final module = allModules[index];
                final isSelected = _selectedModules.contains(module.id);
                return CheckboxListTile(
                  title: Text(module.name),
                  subtitle: Text(module.description ?? ''),
                  value: isSelected,
                  onChanged: (final val) {
                    setState(() {
                      if (val == true) {
                        _selectedModules.add(module.id);
                      } else {
                        _selectedModules.remove(module.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Success() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 100.r, color: Colors.green),
            SizedBox(height: 32.h),
            Text(
              'You\'re All Set!',
              style: GoogleFonts.poppins(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Welcome to BizMod, $_businessName! Let\'s start growing your business.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(onPressed: _prevStep, child: const Text('Back'))
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              _currentStep == _totalSteps - 1
                  ? 'Go to Dashboard'
                  : (_businessName.isNotEmpty
                        ? 'Update & Continue'
                        : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
