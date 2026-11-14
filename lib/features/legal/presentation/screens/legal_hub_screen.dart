import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/legal/domain/legal_document.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Legal & Compliance Hub',
        subtitle: 'Indian Telecommunications & DPDP Standards',
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: context.colorScheme.primary, size: 28),
                AppSpacing.hSpace16,
                Expanded(
                  child: Text(
                    'All legal documentation is packaged offline directly inside this application and can also be viewed on our website.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onPrimaryContainer,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          ...LegalDocType.values.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AppCard(
                variant: AppCardVariant.outlined,
                onTap: () => context.push('/legal/${doc.id}'),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colorScheme.surfaceContainerHighest,
                      foregroundColor: context.colorScheme.primary,
                      child: Icon(doc.icon, size: 20),
                    ),
                    AppSpacing.hSpace14,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vSpace2,
                          Text(
                            doc.subtitle,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }
}

