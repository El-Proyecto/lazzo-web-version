import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/components/common/simple_selection_sheet.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../routes/app_router.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_profile_section.dart';
// import '../widgets/settings_invite_banner.dart'; // REMOVED - not used
import '../widgets/settings_section.dart';
import '../widgets/settings_option_item.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Settings',
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios,
              color: BrandColors.text1,
              size: 20,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: settingsAsync.maybeWhen(
          data: (settings) => profileAsync.when(
            data: (profile) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.screenH,
                vertical: Gaps.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  SettingsProfileSection(
                    avatarUrl: profile.profileImageUrl,
                    name: profile.name,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.editProfile);
                    },
                  ),

                  const SizedBox(height: Gaps.lg),

                  // Invite Banner - REMOVED per user request
                  // SettingsInviteBanner(
                  //   invitesCount: settings.earlyAccessInvites,
                  //   onShare: () {
                  //     ref
                  //         .read(settingsControllerProvider.notifier)
                  //         .shareInvite();
                  //   },
                  // ),
                  // const SizedBox(height: Gaps.lg),

                  // Preferences Section
                  SettingsSection(
                    title: 'Preferences',
                    children: [
                      SettingsOptionItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        trailing: SettingsOptionTrailing.toggle(
                          value: settings.notificationsEnabled,
                          onChanged: (value) {
                            // Show banner feedback
                            TopBanner.showSuccess(
                              context,
                              message: value
                                  ? 'Notifications enabled'
                                  : 'Notifications disabled',
                            );

                            // Update settings
                            ref
                                .read(settingsControllerProvider.notifier)
                                .toggleNotifications(value);
                          },
                        ),
                      ),
                      SettingsOptionItem(
                        icon: Icons.language,
                        title: 'Language',
                        trailing: SettingsOptionTrailing.selection(
                          value: settings.language.toUpperCase(),
                          onTap: () {
                            _showLanguageSelection(
                                context, ref, settings.language);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Gaps.lg),

                  // Feedback & Help Section
                  SettingsSection(
                    title: 'Feedback & Help',
                    children: [
                      // FAQ - COMMENTED OUT per user request (may be useful later)
                      // SettingsOptionItem(
                      //   icon: Icons.help_outline,
                      //   title: 'FAQ',
                      //   trailing: SettingsOptionTrailing.arrow(
                      //     onTap: () {
                      //       // TODO P2: Navigate to FAQ
                      //     },
                      //   ),
                      // ),
                      SettingsOptionItem(
                        icon: Icons.bug_report_outlined,
                        title: 'Report a problem',
                        trailing: SettingsOptionTrailing.arrow(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.reportProblem,
                            );
                          },
                        ),
                      ),
                      SettingsOptionItem(
                        icon: Icons.lightbulb_outline,
                        title: 'Share a suggestion',
                        trailing: SettingsOptionTrailing.arrow(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.shareSuggestion,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Gaps.lg),

                  // Legal Information Section
                  SettingsSection(
                    title: 'Legal Information',
                    children: [
                      SettingsOptionItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        trailing: SettingsOptionTrailing.arrow(
                          onTap: () async {
                            final url = Uri.parse('https://lazzo-invites-web.vercel.app/privacy');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                TopBanner.showError(
                                  context,
                                  message: 'Could not open Privacy Policy',
                                );
                              }
                            }
                          },
                        ),
                      ),
                      // Terms & Conditions - COMMENTED OUT per user request (may be useful later)
                      // SettingsOptionItem(
                      //   icon: Icons.description_outlined,
                      //   title: 'Terms & Conditions',
                      //   trailing: SettingsOptionTrailing.arrow(
                      //     onTap: () {
                      //       // TODO P2: Navigate to terms & conditions
                      //     },
                      //   ),
                      // ),
                    ],
                  ),

                  const SizedBox(height: Gaps.lg),

                  // Actions Section
                  SettingsSection(
                    title: 'Actions',
                    children: [
                      SettingsOptionItem(
                        icon: Icons.logout,
                        title: 'Log out',
                        isDanger: true,
                        trailing: SettingsOptionTrailing.none(
                          onTap: () {
                            _showLogoutDialog(context, ref);
                          },
                        ),
                      ),
                      SettingsOptionItem(
                        icon: Icons.delete_forever,
                        title: 'Delete account',
                        isDanger: true,
                        trailing: SettingsOptionTrailing.none(
                          onTap: () {
                            _showDeleteAccountDialog(context, ref);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Gaps.xl),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading profile',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ),
          ),
          orElse: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _showLanguageSelection(
      BuildContext context, WidgetRef ref, String currentLanguage) async {
    final languageMap = {
      'English': 'en',
      'Português': 'pt',
    };

    // Find current language label
    final currentLabel = languageMap.entries
        .firstWhere((entry) => entry.value == currentLanguage,
            orElse: () => languageMap.entries.first)
        .key;

    final selected = await SimpleSelectionSheet.show(
      context: context,
      title: 'Select Language',
      options: languageMap.keys.toList(),
      selectedOption: currentLabel,
    );

    if (selected != null) {
      final languageCode = languageMap[selected]!;
      ref
          .read(settingsControllerProvider.notifier)
          .updateLanguage(languageCode);
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Log Out',
          message: 'Are you sure you want to log out?',
          confirmText: 'Log Out',
          cancelText: 'Cancel',
          isDestructive: true,
          onConfirm: () async {
            try {
              await ref.read(settingsControllerProvider.notifier).logOut();

              if (context.mounted) {
                // Navigate to login and clear all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.loginPage,
                  (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                TopBanner.showError(
                  context,
                  message: 'Failed to log out. Please try again.',
                );
              }
            }
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Delete Account',
          message:
              'Are you sure you want to delete your account? This action cannot be undone.',
          confirmText: 'Delete',
          cancelText: 'Cancel',
          isDestructive: true,
          onConfirm: () async {
            try {
              await ref
                  .read(settingsControllerProvider.notifier)
                  .deleteAccount();

              if (context.mounted) {
                // Navigate to login and clear all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.loginPage,
                  (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                TopBanner.showError(
                  context,
                  message: 'Failed to delete account. Please try again.',
                );
              }
            }
          },
        );
      },
    );
  }
}
