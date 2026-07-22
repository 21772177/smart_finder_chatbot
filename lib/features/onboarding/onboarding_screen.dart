import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../permissions/permission_dashboard.dart';
import '../settings/settings_service.dart';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getBool('onboarding_complete') ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      ref.invalidate(onboardingCompleteProvider);
    }
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcomePage(theme),
                  _buildAccessibilityPage(theme),
                  _buildSetupPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_page < 2 ? 'Next' : 'Get Started'),
                    ),
                  ),
                  if (_page < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton(
                        onPressed: _complete,
                        child: const Text('Skip'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Second Brain',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI-powered memory assistant. Capture, analyze, and search anything on your screen.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(
            theme,
            Icons.lock,
            'Privacy First',
            'All data stays on your device. Cloud AI is optional.',
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            theme,
            Icons.touch_app,
            'One-Tap Capture',
            'Tap the floating bubble to capture and analyze any screen.',
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            theme,
            Icons.search,
            'Smart Search',
            'Find anything you captured with AI-powered search.',
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.accessibility_new,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Enable Accessibility',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Second Brain needs Accessibility permission to read screen content and show the floating overlay bubble.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.accessibility_new,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Accessibility Service'),
              subtitle: const Text('Required for screen capture'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final service = ref.read(permissionServiceProvider);
                await service.openAccessibilitySettings();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.picture_in_picture,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Display Overlay'),
              subtitle: const Text('Required for floating bubble'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final service = ref.read(permissionServiceProvider);
                await service.openOverlaySettings();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Configure AI',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Add an API key for cloud-powered analysis, or use the built-in local analysis. You can configure this later in Settings.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Cloud AI', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gemini, OpenAI, or Anthropic API key for best results.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Local Analysis', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built-in keyword extraction and summarization. No API key needed.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
