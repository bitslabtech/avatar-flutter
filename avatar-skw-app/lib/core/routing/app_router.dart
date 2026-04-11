/// App routing configuration using go_router
/// Defines all routes and navigation guards
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import 'router_notifier.dart'; // Import this
import '../../features/auth/auth_choice_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/verify_otp_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/product_detail/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/home/screens/category_products_screen.dart';
import '../../features/orders/orders_list_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/screens/dealers_list_screen.dart';
import '../../features/admin/screens/product_management_screen.dart';
import '../../features/admin/screens/category_management_screen.dart';
import '../../features/admin/screens/category_edit_screen.dart';
import '../../features/admin/providers/category_provider.dart';
import '../../features/admin/screens/brand_management_screen.dart';
import '../../features/admin/screens/brand_edit_screen.dart';
import '../../features/admin/screens/gst_management_screen.dart';
import '../../features/admin/screens/product_list_screen.dart';
import '../../features/admin/screens/product_add_edit_screen.dart';
import '../../features/admin/screens/bulk_product_operations_screen.dart';
import '../../features/admin/screens/user_list_screen.dart';
import '../../features/admin/screens/user_add_edit_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_management_screen.dart';
import '../../features/admin/screens/ecommerce_dashboard_screen.dart';
import '../../features/admin/screens/ecommerce_home_screen.dart';
import '../../features/admin/screens/ecommerce_category_screen.dart';
import '../../features/admin/screens/ecommerce_cart_screen.dart';
import '../../features/admin/screens/admin_configurations_screen.dart';
import '../../features/admin/screens/content/admin_policy_list_screen.dart';
import '../../features/admin/screens/content/admin_policy_edit_screen.dart';
import '../../features/admin/screens/admin_contact_settings_screen.dart';
import '../../features/profile/screens/support_screen.dart';
import '../../features/reports/screens/reports_screen.dart';


import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/profile/screens/my_address_screen.dart';
import '../../features/profile/screens/address_add_edit_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/order_history_screen.dart';
import '../../features/admin/screens/order_list_screen.dart';
import '../../features/admin/screens/create_order/admin_create_order_screen.dart';
import '../../features/admin/screens/admin_order_detail_screen.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/system_provider.dart';
import '../../features/common/maintenance_screen.dart';
import '../../features/common/main_layout_screen.dart'; // IMPORTED
import '../../features/home/screens/categories_screen.dart'; // IMPORTED
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/content/policy_list_screen.dart';
import '../../features/content/policy_viewer_screen.dart';
import '../../features/admin/screens/content/admin_policy_list_screen.dart';
import '../../features/admin/screens/content/admin_policy_edit_screen.dart';

// ... (existing code)




/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  final shellNavigatorShopKey = GlobalKey<NavigatorState>(debugLabel: 'shellShop');
  final shellNavigatorCartKey = GlobalKey<NavigatorState>(debugLabel: 'shellCart');
  final shellNavigatorAccountKey = GlobalKey<NavigatorState>(debugLabel: 'shellAccount');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      
      // Don't redirect splash or onboarding
      if (location == '/' || location == '/onboarding') {
        return null;
      }
      
      // Check Authentication & System State
      final authState = ref.read(authProvider);
      final systemState = ref.watch(systemProvider);
      
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = location == '/login' || 
                          location == '/register' ||
                          location == '/auth-choice';
                          
      // Define strictly protected routes (Cart is now OPEN to guests)
      final isProtectedRoute = location.startsWith('/profile/orders') ||
                               location.startsWith('/profile/edit') ||
                               location.startsWith('/profile/addresses'); 
                               // /profile itself triggers redirect below if guest, but we want to allow the ROUTE to exist so Shell works?
                               // Actually, if we want Guest to click "Account" and go to Login, /profile should probably redirect.
      
      final user = authState.user;
      final isAdmin = user?.isAdmin ?? false;

      // Maintenance Mode Check
      if (systemState.maintenanceMode) {
        if (isAdmin) {
          // Fall through
        } else {
          if (isAuthenticated) {
            return '/maintenance';
          }
          if (location == '/login' || location == '/auth-choice') {
             return null; 
          }
          if (location != '/maintenance') {
            return '/maintenance';
          }
          return null;
        }
      } else {
        if (location == '/maintenance') {
          return '/'; // Exit maintenance screen
        }
      }

      // Prevent non-admins from accessing admin routes
      if (location.startsWith('/admin')) {
        if (!isAuthenticated || !isAdmin) {
          return '/auth-choice'; 
        }
      }

      // Admin Redirects
      if (isAuthenticated && isAdmin) {
        if (isAuthRoute || location == '/home' || location == '/') {
          return '/admin';
        }
        if (!location.startsWith('/admin') && location != '/notifications') {
             // Allow profile?
             if (location.startsWith('/profile')) return null;
             return '/admin';
        }
      }
      
      // Protected routes require authentication
      if (!isAuthenticated && isProtectedRoute) {
        return '/auth-choice';
      }
      
      // If Guest tries to access Profile Tab -> Login
      if (!isAuthenticated && location == '/profile') {
        return '/auth-choice';
      }
      
      // If authenticated (CONSUMER/DEALER) and on auth routes, redirect to home
      if (isAuthenticated && !isAdmin && (isAuthRoute || location == '/')) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth-choice',
        name: 'auth-choice',
        builder: (context, state) => const AuthChoiceScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
         path: '/forgot-password',
         builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
         path: '/verify-otp',
         builder: (context, state) {
            final phone = state.extra as String;
            return VerifyOtpScreen(phone: phone);
         },
      ),
      GoRoute(
         path: '/reset-password',
         builder: (context, state) {
            final token = state.extra as String;
            return ResetPasswordScreen(token: token);
         },
      ),
      GoRoute(
        path: '/maintenance',
        name: 'maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),

      // ADMIN ROUTES (Outside Shell)
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
           GoRoute(
             path: 'dealers',
             name: 'admin-dealers',
             builder: (context, state) => const DealersListScreen(),
           ),
           GoRoute(
             path: 'product-management',
             name: 'admin-product-management',
             builder: (context, state) => const ProductManagementScreen(),
           ),
           GoRoute(
             path: 'products',
             name: 'admin-products',
             builder: (context, state) => const ProductListScreen(),
             routes: [
                GoRoute(
                 path: 'add',
                 name: 'admin-product-add',
                 builder: (context, state) => const ProductAddEditScreen(),
                ),
                 GoRoute(
                 path: 'edit/:id',
                 name: 'admin-product-edit',
                  builder: (context, state) {
                    final product = state.extra as Product?;
                    return ProductAddEditScreen(product: product);
                  },
                ),
                GoRoute(
                  path: 'bulk',
                  name: 'admin-product-bulk',
                  builder: (context, state) => const BulkProductOperationsScreen(),
                ),
             ]
           ),
           GoRoute(
             path: 'users',
             name: 'admin-users',
              builder: (context, state) => const UserListScreen(),
              routes: [

                GoRoute(
                  path: 'edit',
                  name: 'admin-user-edit',
                  builder: (context, state) {
                    final user = state.extra as User?;
                    return UserAddEditScreen(user: user);
                  },
                ),
              ],
            ),
           GoRoute(
             path: 'orders',
             name: 'admin-orders',
             builder: (context, state) => const OrderListScreen(),
             routes: [
               GoRoute(
                 path: 'create',
                 name: 'admin-create-order',
                 builder: (context, state) => const AdminCreateOrderScreen(),
               ),
               GoRoute(
                 path: ':id',
                 name: 'admin-order-detail',
                 builder: (context, state) {
                    final orderId = state.pathParameters['id']!;
                    return AdminOrderDetailScreen(orderId: orderId);
                 },
               ),
             ],
           ),
           GoRoute(
             path: 'brands',
             name: 'admin-brands',
             builder: (context, state) => const BrandManagementScreen(),
             routes: [
               GoRoute(
                 path: 'edit/:id',
                 name: 'admin-brand-edit',
                 builder: (context, state) => BrandEditScreen(brandId: state.pathParameters['id']!),
               ),
             ],
           ),
           GoRoute(
             path: 'gst',
             name: 'admin-gst',
             builder: (context, state) => const GstManagementScreen(),
           ),
           GoRoute(
             path: 'settings',
             name: 'admin-settings',
              builder: (context, state) => const AdminSettingsScreen(),
            ),
            GoRoute(
              path: 'admins',
              name: 'admin-management',
              builder: (context, state) => const AdminManagementScreen(),
            ),
            GoRoute(
              path: 'configurations',
              name: 'admin-configurations',
              builder: (context, state) => const AdminConfigurationsScreen(),
            ),
             GoRoute(
              path: 'policies',
              name: 'admin-policy-list',
              builder: (context, state) => const AdminPolicyListScreen(),
              routes: [
                GoRoute(
                  path: 'edit/:key',
                  name: 'admin-policy-edit',
                  builder: (context, state) {
                    final key = state.pathParameters['key']!;
                    return AdminPolicyEditScreen(contentKey: key);
                  },
                ),
              ],
            ),
           GoRoute(
             path: 'contact-settings',
             name: 'admin-contact-settings',
             builder: (context, state) => const AdminContactSettingsScreen(),
           ),
           GoRoute(
             path: 'ecommerce',
             name: 'admin-ecommerce',
             builder: (context, state) => const EcommerceDashboardScreen(),
             routes: [
                GoRoute(
                  path: 'home',
                  name: 'admin-ecommerce-home',
                  builder: (context, state) => const EcommerceHomeScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  name: 'admin-ecommerce-categories',
                  builder: (context, state) => const EcommerceCategoryScreen(),
                ),
                 GoRoute(
                  path: 'cart',
                  name: 'admin-ecommerce-cart',
                  builder: (context, state) => const EcommerceCartScreen(),
                ),

             ],
           ),
           GoRoute(
             path: 'reports',
             name: 'admin-reports',
             builder: (context, state) => const ReportsScreen(),
           ),
           GoRoute(
             path: 'categories',
             name: 'admin-categories',
             builder: (context, state) => const CategoryManagementScreen(),
             routes: [
               GoRoute(
                 path: 'edit/:id',
                 name: 'admin-category-edit',
                 builder: (context, state) {
                    final item = state.extra as CategoryItem?;
                    return CategoryEditScreen(category: item);
                 },
               ),
             ],
           ),
        ],
      ),

      // BOTTOM NAVIGATION SHELL
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          // BRANCH 1: HOME
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) {
                  final category = state.uri.queryParameters['category'];
                  return HomeScreen(initialCategory: category);
                },
                routes: [

                  GoRoute(
                    path: 'category/:name',
                    name: 'category-products',
                    builder: (context, state) {
                       final categoryName = state.pathParameters['name']!;
                       return CategoryProductsScreen(categoryName: categoryName);
                    },
                  ),
                ]
              ),
            ],
          ),

          // BRANCH 2: CATEGORIES (SHOP)
          StatefulShellBranch(
            navigatorKey: shellNavigatorShopKey,
            routes: [
              GoRoute(
                path: '/categories',
                name: 'categories',
                builder: (context, state) => const CategoriesScreen(),
                routes: [
                   GoRoute(
                     path: 'details/:name',
                     name: 'shop-category-details',
                     builder: (context, state) {
                       final categoryName = state.pathParameters['name']!;
                       return CategoryProductsScreen(categoryName: categoryName);
                     },
                   ),
                ]
              ),
            ],
          ),

          // BRANCH 3: CART
          StatefulShellBranch(
            navigatorKey: shellNavigatorCartKey,
            routes: [
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder: (context, state) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    name: 'checkout',
                    parentNavigatorKey: rootNavigatorKey, // Hide bottom bar
                    builder: (context, state) => const CheckoutScreen(),
                  ),
                ]
              ),
            ],
          ),

          // BRANCH 4: ACCOUNT (PROFILE)
          StatefulShellBranch(
            navigatorKey: shellNavigatorAccountKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                   GoRoute(
                     path: 'edit',
                     parentNavigatorKey: rootNavigatorKey,
                     builder: (context, state) => const EditProfileScreen(),
                   ),
                   GoRoute(
                     path: 'addresses',
                     builder: (context, state) => const MyAddressScreen(),
                     routes: [
                       GoRoute(
                         path: 'add',
                         builder: (context, state) => const AddressAddEditScreen(),
                       ),
                       GoRoute(
                         path: 'edit/:id',
                         builder: (context, state) {
                            final addressId = state.pathParameters['id']!;
                            return AddressAddEditScreen(addressId: addressId);
                         },
                       ),
                     ],
                   ),

                   GoRoute(
                     path: 'policies',
                     name: 'policies',
                     builder: (context, state) => const PolicyListScreen(),
                     routes: [
                       GoRoute(
                         path: 'view/:key',
                         name: 'policy-viewer',
                         parentNavigatorKey: rootNavigatorKey,
                         builder: (context, state) {
                            final key = state.pathParameters['key']!;
                            return PolicyViewerScreen(contentKey: key);
                         },
                       ),
                     ],
                   ),
                   GoRoute(
                     path: 'support',
                     name: 'support',
                     builder: (context, state) => const SupportScreen(),
                   ),
                   GoRoute(
                  path: 'wishlist',
                  name: 'wishlist',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const WishlistScreen(),
                ),
                GoRoute(
                  path: 'orders',
                    name: 'orders',
                    builder: (context, state) => const OrdersListScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail/:id',
                        name: 'order-detail',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final orderId = state.pathParameters['id']!;
                          return OrderDetailScreen(orderId: orderId);
                        },
                      ),
                    ]
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      
      // OTHER ROUTES (Root Level)
      GoRoute(
        path: '/add-address',
        name: 'add-address',
        builder: (context, state) => const AddressAddEditScreen(),
      ),
      GoRoute(
        path: '/edit-address/:id',
        name: 'edit-address',
        builder: (context, state) {
          final addressId = state.pathParameters['id'];
          return AddressAddEditScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/order-success',
        name: 'order-success',
        builder: (context, state) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/order-history', // Alias for orders
        name: 'order-history',
        redirect: (_, __) => '/profile/orders',
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      // Legacy Redirect: /category/:name -> /home/category/:name
      GoRoute(
        path: '/category/:name',
        redirect: (context, state) {
           return '/home/category/${state.pathParameters['name']}';
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
