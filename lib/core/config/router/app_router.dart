import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/accept_invite_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/dashboard/presentation/pages/analytics_page.dart';
import '../../../features/dashboard/presentation/pages/expenses_page.dart';
import '../../../features/dashboard/presentation/pages/employee_management_page.dart';
import '../../../features/modules/presentation/pages/modules_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/profile/presentation/pages/business_profile_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../../../features/zakat_tracker/presentation/zakat_page.dart';
import '../../../features/inventory/presentation/pages/inventory_dashboard_page.dart';
import '../../../features/inventory/presentation/pages/add_edit_product_page.dart';
import '../../../features/inventory/presentation/pages/suppliers_page.dart';
import '../../../features/inventory/presentation/pages/restock_page.dart';
import '../../../features/inventory/presentation/pages/import_wizard/import_wizard_page.dart';
import '../../../features/inventory/data/models/product_model.dart';
import '../../../features/pos/data/models/sale_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../features/pos/presentation/pages/pos_page.dart';
import '../../../features/pos/presentation/pages/sales_history_page.dart';
import '../../../features/pos/presentation/pages/customer_management_page.dart';
import '../../../features/pos/presentation/pages/sale_success_page.dart';
import '../../../features/payments/presentation/pages/transfers_page.dart';
import '../../../features/receipts/presentation/pages/receipt_designer_page.dart';
import '../../../features/receipts/presentation/pages/printer_settings_page.dart';
import '../../../features/onboarding/presentation/pages/business_onboarding_page.dart';
import '../../../shared/presentation/pages/coming_soon_page.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/splash_screen.dart';
import '../../../shared/presentation/widgets/main_navigation_container.dart';

final routerProvider = Provider<GoRouter>((final ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: AppRouter.rootNavigatorKey,
    initialLocation: AppRouter.splash,
    redirect: (final context, final state) {
      final loggedIn = authState.user != null;
      final isLoggingIn = state.uri.toString() == AppRouter.login || state.uri.toString() == AppRouter.register;
      final isOnboarding = state.uri.toString().startsWith('/onboarding');
      final isInitialOnboardingDone = authState.isInitialOnboardingDone;

      // 1. Initial App Onboarding
      if (!isInitialOnboardingDone && !isOnboarding) {
        return AppRouter.onboarding;
      }
      if (isInitialOnboardingDone && state.uri.toString() == AppRouter.onboarding) {
        return loggedIn ? AppRouter.dashboard : AppRouter.login;
      }

      // 2. Auth Guard
      if (!loggedIn && !isLoggingIn && !isOnboarding) return AppRouter.login;
      if (loggedIn && isLoggingIn) return AppRouter.dashboard;
      
      // 3. Business Onboarding
      if (loggedIn && authState.isOnboarding && state.uri.toString() != AppRouter.businessOnboarding) {
        return AppRouter.businessOnboarding;
      }

      return null;
    },
    routes: AppRouter.router.configuration.routes,
  );
});

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String businessOnboarding = '/onboarding/business';
  static const String login = '/login';
  static const String register = '/register';
  static const String acceptInvite = '/accept-invite';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String expenses = '/expenses';
  static const String employees = '/employees';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String restock = '/restock';
  static const String importWizard = '/import-wizard';
  static const String receiptDesigner = '/receipt-designer';
  static const String printerSettings = '/printer-settings';
  static const String modules = '/modules';
  static const String profile = '/profile';
  static const String businessProfile = '/business-profile';
  static const String settings = '/settings';
  static const String menu = '/menu';
  static const String more = '/more';
  static const String zakat = '/zakat';
  static const String inventory = '/inventory';
  static const String pos = '/pos';
  static const String salesHistory = '/sales-history';
  static const String transfers = '/transfers';
  static const String saleSuccess = '/sale-success';
  static const String comingSoon = '/coming-soon';

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (final context, final state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (final context, final state) => const OnboardingPage(),
      ),
      GoRoute(
        path: businessOnboarding,
        name: 'business-onboarding',
        builder: (final context, final state) => const BusinessOnboardingPage(),
      ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (final context, final state) => const LoginPage(),
        ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (final context, final state) => const RegisterPage(),
      ),
      
      // Invitation Landing
      GoRoute(
        path: acceptInvite,
        name: 'accept-invite',
        builder: (final context, final state) {
          final inviteId = state.uri.queryParameters['inviteId'] ?? '';
          return AcceptInvitePage(inviteId: inviteId);
        },
      ),

      // Main App Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (final context, final state, final child) => MainNavigationContainer(child: child),
        routes: [
          GoRoute(
            path: dashboard,
            name: 'dashboard',
            builder: (final context, final state) => const DashboardPage(),
          ),
          GoRoute(
            path: analytics,
            name: 'analytics',
            builder: (final context, final state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: expenses,
            name: 'expenses',
            builder: (final context, final state) => const ExpensesPage(),
          ),
          GoRoute(
            path: employees,
            name: 'employees',
            builder: (final context, final state) => const EmployeeManagementPage(),
          ),
          GoRoute(
            path: customers,
            name: 'customers',
            builder: (final context, final state) => const CustomerManagementPage(),
          ),
          GoRoute(
            path: suppliers,
            name: 'suppliers',
            builder: (final context, final state) => const SuppliersPage(),
          ),
          GoRoute(
            path: restock,
            name: 'restock',
            builder: (final context, final state) => const RestockPage(),
          ),
          GoRoute(
            path: importWizard,
            name: 'import-wizard',
            builder: (final context, final state) => const ImportWizardPage(),
          ),
          GoRoute(
            path: receiptDesigner,
            name: 'receipt-designer',
            builder: (final context, final state) => const ReceiptDesignerPage(),
          ),
          GoRoute(
            path: printerSettings,
            name: 'printer-settings',
            builder: (final context, final state) => const PrinterSettingsPage(),
          ),
          GoRoute(
            path: inventory,
            name: 'inventory-dashboard',
            builder: (final context, final state) => const InventoryDashboardPage(),
          ),
          GoRoute(
            path: pos,
            name: 'pos',
            builder: (final context, final state) => const PosPage(),
          ),
          GoRoute(
            path: salesHistory,
            name: 'sales-history',
            builder: (final context, final state) => const SalesHistoryPage(),
          ),
          GoRoute(
            path: transfers,
            name: 'transfers',
            builder: (final context, final state) => const TransfersPage(),
          ),
          GoRoute(
            path: zakat,
            name: 'zakat-overview',
            builder: (final context, final state) => const ZakatPage(),
          ),
          GoRoute(
            path: settings,
            name: 'settings',
            builder: (final context, final state) => const SettingsPage(),
          ),
          GoRoute(
            path: menu,
            name: 'menu',
            builder: (final context, final state) => const SettingsPage(),
          ),
          GoRoute(
            path: more,
            name: 'more',
            builder: (final context, final state) => const SettingsPage(),
          ),
          GoRoute(
            path: '$comingSoon/:title',
            name: 'coming-soon',
            builder: (final context, final state) {
              final title = state.pathParameters['title'] ?? 'Feature';
              return ComingSoonPage(title: title);
            },
          ),
        ],
      ),

      GoRoute(
        path: '$inventory/add-edit',
        name: 'add-edit-product',
        parentNavigatorKey: rootNavigatorKey,
        builder: (final context, final state) {
          final product = state.extra as ProductModel?;
          return AddEditProductPage(product: product);
        },
      ),
      GoRoute(
        path: saleSuccess,
        name: 'sale-success',
        parentNavigatorKey: rootNavigatorKey,
        builder: (final context, final state) {
          final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
          return Scaffold(
            body: SaleSuccessPage(
              sale: extra['sale'] as SaleModel,
              business: extra['business'] as BusinessModel?,
            ),
          );
        },
      ),

      GoRoute(
        path: profile,
        name: 'profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (final context, final state) => const ProfilePage(),
      ),
      GoRoute(
        path: businessProfile,
        name: 'businessProfile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (final context, final state) => const BusinessProfilePage(),
      ),
      GoRoute(
        path: modules,
        name: 'modules',
        parentNavigatorKey: rootNavigatorKey,
        builder: (final context, final state) => const ModulesPage(),
      ),
    ],
    
    errorBuilder: (final context, final state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('The page you are looking for does not exist.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go(dashboard), child: const Text('Go to Dashboard')),
          ],
        ),
      ),
    ),
  );
}
