import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================================
// 1. ROUTING CONTRACT & CONFIGURATION
// ============================================================================

/// Type-safe route identifiers avoiding hardcoded magic strings.
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String find = '/find';
  static const String add = '/add';
  static const String report = '/report';
  static const String reports = '/reports';
  static const String profile = '/profile';
}

/// Strongly-typed action descriptor for dashboard grid and quick navigation.
@immutable
class DashboardActionItem {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color? accentColor;

  const DashboardActionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.accentColor,
  });
}

// ============================================================================
// 2. DASHBOARD PAGE (VIEW)
// ============================================================================

class DashboardPage extends StatefulWidget {
  final FirebaseAuth? auth;

  const DashboardPage({super.key, this.auth});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final FirebaseAuth _auth;
  late final TextEditingController _searchController;
  int _currentNavIndex = 0;

  static const List<DashboardActionItem> _quickActions = [
    DashboardActionItem(
      title: 'Find Person',
      description: 'Search missing registry database',
      icon: Icons.search_rounded,
      route: AppRoutes.find,
    ),
    DashboardActionItem(
      title: 'Add Person',
      description: 'Log verified details to records',
      icon: Icons.person_add_alt_1_rounded,
      route: AppRoutes.add,
    ),
    DashboardActionItem(
      title: 'Report Incident',
      description: 'Emergency priority broadcast',
      icon: Icons.warning_amber_rounded,
      route: AppRoutes.report,
      accentColor: Colors.amber,
    ),
    DashboardActionItem(
      title: 'My Filings',
      description: 'Track status and active updates',
      icon: Icons.assignment_outlined,
      route: AppRoutes.reports,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushNamed(route);
  }

  void _handleDrawerNavigation(String route) {
    // Pop drawer first to preserve memory and stack integrity
    Navigator.of(context).pop();
    _navigateTo(route);
  }

  void _onBottomNavSelected(int index) {
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        break; // Already on dashboard
      case 1:
        _navigateTo(AppRoutes.find);
        break;
      case 2:
        _navigateTo(AppRoutes.add);
        break;
      case 3:
        _navigateTo(AppRoutes.profile);
        break;
    }
  }

  void _handleSearchSubmit(String query) {
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) return;

    _searchController.clear();
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(
      AppRoutes.find,
      arguments: {'query': sanitizedQuery},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Finder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new alerts at this time.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      drawer: _AppDrawer(
        user: user,
        onNavigate: _handleDrawerNavigation,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Hook up remote sync/data refresh logic here
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _GreetingHeader(userName: user?.displayName),
                    const SizedBox(height: 20),
                    _SearchBarWidget(
                      controller: _searchController,
                      onSubmit: _handleSearchSubmit,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Emergency Directory Services',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _quickActions[index];
                      return _ActionGridCard(
                        action: item,
                        onTap: () => _navigateTo(item.route),
                      );
                    },
                    childCount: _quickActions.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _OperationalNoticeBanner(
                    onTapHelp: () => _navigateTo(AppRoutes.find),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: _onBottomNavSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Register',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. INTERNAL PRESENTATION SUB-WIDGETS
// ============================================================================

class _GreetingHeader extends StatelessWidget {
  final String? userName;

  const _GreetingHeader({this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = userName != null && userName!.trim().isNotEmpty
        ? 'Welcome back, ${userName!.trim().split(' ').first} 👋'
        : 'Welcome 👋';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Centralized missing persons registry and response system.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  const _SearchBarWidget({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: 'Search by legal name, age, or location...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: 'Search',
          onPressed: () => onSubmit(controller.text),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
      ),
    );
  }
}

class _ActionGridCard extends StatelessWidget {
  final DashboardActionItem action;
  final VoidCallback onTap;

  const _ActionGridCard({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = action.accentColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, size: 28, color: accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationalNoticeBanner extends StatelessWidget {
  final VoidCallback onTapHelp;

  const _OperationalNoticeBanner({required this.onTapHelp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 28,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Safety Network',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reports filed are propagated directly through official responders. Contact regional authorities in life-threatening scenarios.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final User? user;
  final ValueChanged<String> onNavigate;

  const _AppDrawer({
    required this.user,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(
              user?.displayName ?? 'Anonymous Responder',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'Unverified Session',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  onTap: () => onNavigate(AppRoutes.dashboard),
                ),
                ListTile(
                  leading: const Icon(Icons.search_rounded),
                  title: const Text('Find Person'),
                  onTap: () => onNavigate(AppRoutes.find),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Add Person'),
                  onTap: () => onNavigate(AppRoutes.add),
                ),
                ListTile(
                  leading: const Icon(Icons.notification_important_outlined),
                  title: const Text('Report Missing'),
                  onTap: () => onNavigate(AppRoutes.report),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('My Reports'),
                  onTap: () => onNavigate(AppRoutes.reports),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Profile'),
                  onTap: () => onNavigate(AppRoutes.profile),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'v1.0.0 • Secure Response Protocol',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}