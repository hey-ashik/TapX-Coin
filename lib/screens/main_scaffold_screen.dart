import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tap_engine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/notification_modal.dart';
import '../widgets/particle_layer.dart';
import '../widgets/user_profile_modal.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'tap_engine_screen.dart';
import 'withdrawals_screen.dart';

class MainScaffoldScreen extends StatefulWidget {
  const MainScaffoldScreen({super.key});

  @override
  State<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends State<MainScaffoldScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = const [
    LeaderboardScreen(),
    TapEngineScreen(),
    WithdrawalsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = context.read<AuthProvider>().activeTab;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context.read<TapEngineProvider>().syncWithUser(user.totalTaps, user.level);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showNotificationsSheet() {
    HapticFeedback.lightImpact();
    NotificationModal.show(context);
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    context.read<AuthProvider>().setActiveTab(index);
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tapEngine = context.watch<TapEngineProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: AppAvatar(
            imageUrl: auth.currentUser.avatarUrl,
            name: auth.currentUser.name.isNotEmpty
                ? auth.currentUser.name
                : auth.currentUser.username,
            size: 32,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            UserProfileModal.show(context, user: auth.currentUser);
          },
        ),
        title: Text(
          'TapX',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 20,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
              ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: AppColors.primary),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: _showNotificationsSheet,
          ),
        ],
      ),
      body: ColoredBox(
        color: const Color(0xFF000000),
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ParticleLayer(
                  particles: tapEngine.particles,
                  onParticleFinished: (id) => tapEngine.removeParticle(id),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
