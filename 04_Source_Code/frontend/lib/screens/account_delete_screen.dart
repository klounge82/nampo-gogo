import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/profile_provider.dart';
import '../l10n/app_localizations.dart';

class AccountDeleteScreen extends StatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends State<AccountDeleteScreen> {
  bool _agreeToTerms = false;
  bool _isSubmitting = false;

  Future<void> _submitWithdrawal(AppLocalizations l10n) async {
    if (!_agreeToTerms) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ProfileProvider>().withdrawAccount(context);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountDeleteDoneTitle),
            content: Text(l10n.accountDeleteDoneBody),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  // Clean screen stack and go back to auth screen
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: Text(l10n.confirmOk),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String rawMsg = e.toString();
        int? statusCode;
        if (e is DioException) {
          statusCode = e.response?.statusCode;
        }

        if (statusCode == 401) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.loginTitle),
              content: Text(l10n.reservationMemberOnlyNotice),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirmOk),
                ),
              ],
            ),
          );
        } else if (statusCode == 409 || rawMsg.contains('409') || rawMsg.contains('소유 중인 사업장')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.accountDeleteBlockedTitle),
              content: Text(l10n.accountDeleteBlockedBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirmOk),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Text(
                l10n.accountDeleteErrorSnackBar,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    debugPrint('AccountDeleteScreen locale = ${l10n.localeName}');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deleteAccount),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ACCOUNT-DELETE: M04J',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.accountDeleteNoticeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.accountDeleteSec1Title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${l10n.accountDeleteSec1Body}\n',
                            ),
                            Text(
                              l10n.accountDeleteSec2Title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text('${l10n.accountDeleteSec2Body}\n'),
                            Text(
                              l10n.accountDeleteSec3Title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${l10n.accountDeleteSec3Body}\n',
                            ),
                            Text(
                              l10n.accountDeleteSec4Title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              l10n.accountDeleteSec4Body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: Text(
                      l10n.accountDeleteAgreeCheckbox,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    value: _agreeToTerms,
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      setState(() {
                        _agreeToTerms = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_agreeToTerms && !_isSubmitting)
                        ? () => _submitWithdrawal(l10n)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.redAccent,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(
                      l10n.accountDeleteFinalButton,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ACCOUNT-DELETE: M04J',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
