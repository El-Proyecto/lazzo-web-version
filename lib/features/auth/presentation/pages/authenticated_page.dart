import 'package:flutter/material.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ⬇️ Ajusta estes imports para os caminhos onde guardaste os widgets
import '../widgets/authenticated_user/features_auth_list.dart';
import '../../../auth/presentation/widgets/authenticated_user/authenticated_header.dart';
import '../widgets/authenticated_user/authenticated_footer.dart';
import '../../../../routes/app_router.dart';
class OnboardingSuccessPage extends StatelessWidget {
  const OnboardingSuccessPage({super.key});

  /*void _goToHome(BuildContext context) {
    // Troca '/' por AppRouter.authHomepage se usares o teu AppRouter
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const SizedBox.shrink()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: WelcomeAccountCreated()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: FeatureCardsList()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GetStartedCta(onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRouter.mainLayout, (_) => false);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}
