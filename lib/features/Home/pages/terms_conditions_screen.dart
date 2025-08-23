import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedNote,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terms & Conditions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: December 2024',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withAlpha(180),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              'Welcome to Campus Mapper',
              'These Terms and Conditions ("Terms", "Terms and Conditions") govern your relationship with Campus Mapper mobile application (the "Service") operated by ARKSoft ("us", "we", or "our").\n\nPlease read these Terms and Conditions carefully before using our Campus Mapper mobile application (the "Service").\n\nYour access to and use of the Service is conditioned on your acceptance of and compliance with these Terms. These Terms apply to all visitors, users and others who access or use the Service.\n\nBy accessing or using the Service you agree to be bound by these Terms. If you disagree with any part of these terms then you may not access the Service.',
            ),

            // App Description
            _buildSection(
              context,
              '1. Description of Service',
              'Campus Mapper is a mobile navigation application designed to help students and visitors navigate campus locations efficiently. The Service includes features such as:\n\n• Interactive campus map with location search\n• Turn-by-turn navigation and directions\n• Location categorization (classes, food, ATMs, etc.)\n• Personal history and activity tracking\n• Route planning with distance and calorie calculations\n• Offline map capabilities\n• User preferences and settings',
            ),

            // User Accounts
            _buildSection(
              context,
              '2. User Accounts',
              'When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for maintaining the confidentiality of your account.\n\nYou agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.\n\nYou may not use as a username the name of another person or entity or that is not lawfully available for use, a name or trademark that is subject to any rights of another person or entity other than you without appropriate authorization, or a name that is otherwise offensive, vulgar or obscene.',
            ),

            // Acceptable Use
            _buildSection(
              context,
              '3. Acceptable Use',
              'You may use our Service only for lawful purposes and in accordance with these Terms. You agree not to use the Service:\n\n• In any way that violates any applicable federal, state, local, or international law or regulation\n• To impersonate or attempt to impersonate the Company, a Company employee, another user, or any other person or entity\n• To engage in any other conduct that restricts or inhibits anyone\'s use or enjoyment of the Service\n• To attempt to interfere with, compromise the system integrity or security of the Service\n• To collect or track the personal information of others without their consent',
            ),

            // Location Services
            _buildSection(
              context,
              '4. Location Services and Privacy',
              'Campus Mapper requires access to your device\'s location services to provide navigation and mapping functionality. By using our Service, you consent to the collection and use of your location data as described in our Privacy Policy.\n\nLocation data is used to:\n• Provide accurate navigation and directions\n• Calculate distances and routes\n• Track your journey progress\n• Improve our mapping services\n\nYou can disable location services at any time through your device settings, but this may limit the functionality of the Service.',
            ),

            // User Content
            _buildSection(
              context,
              '5. User Content',
              'Our Service may allow you to post, link, store, share and otherwise make available certain information, text, graphics, or other material ("Content"). You are responsible for the Content that you post to the Service, including its legality, reliability, and appropriateness.\n\nBy posting Content to the Service, you grant us the right and license to use, modify, publicly perform, publicly display, reproduce, and distribute such Content on and through the Service.\n\nYou retain any and all of your rights to any Content you submit, post or display on or through the Service and you are responsible for protecting those rights.',
            ),

            // Prohibited Uses
            _buildSection(
              context,
              '6. Prohibited Uses',
              'You may not use our Service:\n\n• For any unlawful purpose or to solicit others to perform or participate in any unlawful acts\n• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n• To submit false or misleading information\n• To upload or transmit viruses or any other type of malicious code\n• To spam, phish, pharm, pretext, spider, crawl, or scrape\n• For any obscene or immoral purpose or to engage in any other conduct that restricts or inhibits anyone\'s use or enjoyment of the Service',
            ),

            // Intellectual Property
            _buildSection(
              context,
              '7. Intellectual Property Rights',
              'The Service and its original content, features and functionality are and will remain the exclusive property of ARKSoft and its licensors. The Service is protected by copyright, trademark, and other laws. Our trademarks and trade dress may not be used in connection with any product or service without our prior written consent.',
            ),

            // Disclaimer
            _buildSection(
              context,
              '8. Disclaimer',
              'The information on this Service is provided on an "as is" basis. To the fullest extent permitted by law, this Company:\n\n• Excludes all representations and warranties relating to this Service and its contents\n• Excludes all liability for damages arising out of or in connection with your use of this Service\n\nPlease note that navigation and location services may not always be accurate. Users should use their own judgment and verify directions independently, especially in emergency situations.',
            ),

            // Limitation of Liability
            _buildSection(
              context,
              '9. Limitation of Liability',
              'In no event shall ARKSoft, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the Service.',
            ),

            // Termination
            _buildSection(
              context,
              '10. Termination',
              'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.\n\nUpon termination, your right to use the Service will cease immediately. If you wish to terminate your account, you may simply discontinue using the Service.',
            ),

            // Changes to Terms
            _buildSection(
              context,
              '11. Changes to Terms',
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.\n\nWhat constitutes a material change will be determined at our sole discretion. By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms.',
            ),

            // Contact Information
            _buildSection(
              context,
              '12. Contact Us',
              'If you have any questions about these Terms and Conditions, please contact us:\n\n• By email: support@suptle.com\n• Through the app: Use the feedback option in Settings\n\nWe will respond to your inquiries as promptly as possible.',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Thank you for using Campus Mapper',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using our app, you acknowledge that you have read and understood these Terms and Conditions.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
