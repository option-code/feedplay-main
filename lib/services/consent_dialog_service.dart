import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class ConsentDialogService {
  static const String _consentAcceptedKey = 'consent_dialog_accepted';

  /// Check if user has already accepted the consent dialog
  static Future<bool> hasAcceptedConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentAcceptedKey) ?? false;
  }

  /// Mark consent as accepted
  static Future<void> markConsentAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentAcceptedKey, true);
  }

  /// Show consent dialog if not already accepted
  static Future<void> showConsentDialogIfNeeded(BuildContext context) async {
    final hasAccepted = await hasAcceptedConsent();
    if (!hasAccepted && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false, // User must accept to continue
        builder: (context) => const _ConsentDialog(),
      );
    }
  }

  /// Open Privacy Policy in browser
  static Future<void> openPrivacyPolicy() async {
    final url = Uri.parse('https://feedplay.vercel.app/Privacy_Policy.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Terms & Conditions in browser
  static Future<void> openTermsConditions() async {
    final url = Uri.parse('https://feedplay.vercel.app/Terms_Conditions.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _ConsentDialog extends StatelessWidget {
  const _ConsentDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).appColors.cardBackground,
              Theme.of(context).appColors.cardBackground.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Welcome to FeedPlay',
              style: TextStyle(
                color: Theme.of(context).appColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              'Please read and accept our Privacy Policy and Terms & Conditions to continue using the app.',
              style: TextStyle(
                color: Theme.of(context).appColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Privacy Policy Link
            InkWell(
              onTap: () => ConsentDialogService.openPrivacyPolicy(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .appColors
                      .screenBackground
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: Theme.of(context).appColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Theme.of(context).appColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: Theme.of(context).appColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Terms & Conditions Link
            InkWell(
              onTap: () => ConsentDialogService.openTermsConditions(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .appColors
                      .screenBackground
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Theme.of(context).appColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Theme.of(context).appColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: Theme.of(context).appColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ConsentDialogService.markConsentAccepted();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'I Accept',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
