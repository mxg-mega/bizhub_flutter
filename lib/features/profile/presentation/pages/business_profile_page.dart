import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/business_service.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/currency_provider.dart';

class BusinessProfilePage extends ConsumerStatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  ConsumerState<BusinessProfilePage> createState() =>
      _BusinessProfilePageState();
}

class _BusinessProfilePageState extends ConsumerState<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;

  String _currency = 'NGN';
  String _industry = 'retail';
  String _size = 'small';
  bool _isLoading = false;

  final List<Map<String, String>> _availableCurrencies = const [
    {'code': 'NGN', 'symbol': '₦', 'name': 'Nigerian Naira'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling'},
    {'code': 'GHS', 'symbol': 'GH₵', 'name': 'Ghanaian Cedi'},
    {'code': 'CAD', 'symbol': 'CA\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'ZAR', 'symbol': 'R', 'name': 'South African Rand'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham'},
  ];

  @override
  void initState() {
    super.initState();
    final business = ref.read(currentBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? '');
    _phoneController = TextEditingController(text: business?.phone ?? '');
    _emailController = TextEditingController(text: business?.email ?? '');
    _addressController = TextEditingController(text: business?.address ?? '');
    _websiteController = TextEditingController(text: business?.website ?? '');
    _currency =
        business?.currency ?? business?.settings?['currencyCode'] ?? 'NGN';
    _industry = business?.industry ?? 'retail';
    _size = business?.size ?? 'small';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final business = ref.read(currentBusinessProvider);
    if (business == null || business.id == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = await BusinessService().updateBusinessInfo(
        businessId: business.id!,
        name: _nameController.text.trim(),
        currency: _currency,
        industry: _industry,
        size: _size,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
      );

      if (updated != null) {
        await ref.read(authProvider.notifier).updateActiveBusiness(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business info updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating business: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Business Info & Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (final v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                value: _availableCurrencies.any((c) => c['code'] == _currency)
                    ? _currency
                    : 'NGN',
                decoration: const InputDecoration(
                  labelText: 'Default Currency *',
                  prefixIcon: Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(),
                ),
                items: _availableCurrencies.map((final c) {
                  return DropdownMenuItem<String>(
                    value: c['code'],
                    child: Text('${c['code']} (${c['symbol']}) - ${c['name']}'),
                  );
                }).toList(),
                onChanged: (final val) {
                  if (val != null) setState(() => _currency = val);
                },
              ),
              SizedBox(height: 24.h),

              _buildSectionTitle('Industry & Size'),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: _industry,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'retail', child: Text('🏪 Retail')),
                  DropdownMenuItem(
                    value: 'services',
                    child: Text('💇 Services'),
                  ),
                  DropdownMenuItem(
                    value: 'wholesale',
                    child: Text('📦 Wholesale'),
                  ),
                  DropdownMenuItem(
                    value: 'food',
                    child: Text('🍔 Food & Beverage'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('💼 Other')),
                ],
                onChanged: (final val) {
                  if (val != null) setState(() => _industry = val);
                },
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                value: _size,
                decoration: const InputDecoration(
                  labelText: 'Business Size',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'solo',
                    child: Text('👤 Solo (Just me)'),
                  ),
                  DropdownMenuItem(
                    value: 'small',
                    child: Text('👥 Small (2-10 staff)'),
                  ),
                  DropdownMenuItem(
                    value: 'growing',
                    child: Text('👨‍👩‍👧 Growing (11-50 staff)'),
                  ),
                  DropdownMenuItem(
                    value: 'established',
                    child: Text('🏢 Established (50+ staff)'),
                  ),
                ],
                onChanged: (final val) {
                  if (val != null) setState(() => _size = val);
                },
              ),
              SizedBox(height: 24.h),

              _buildSectionTitle('Contact Details'),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Business Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Physical Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Business Details',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(final String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}
