import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/group_entity.dart';
import '../providers/groups_provider.dart';

class GroupCreatedPage extends ConsumerStatefulWidget {
  final GroupEntity group;

  const GroupCreatedPage({super.key, required this.group});

  @override
  ConsumerState<GroupCreatedPage> createState() => _GroupCreatedPageState();
}

class _GroupCreatedPageState extends ConsumerState<GroupCreatedPage> {
  late String qrCodeData;

  @override
  void initState() {
    super.initState();
    qrCodeData = 'https://lazzo.app/groups/${widget.group.id}';
    
    print('🎯 [GroupCreatedPage] Initialized with group: ${widget.group.id}');
    print('   📱 Generated QR code: $qrCodeData');
    print('   🔍 Group has qrCode field: ${widget.group.qrCode}');
    print('   🔍 Group has groupUrl field: ${widget.group.groupUrl}');
    
    // Salvar QR code no Supabase (funciona como backup se não foi salvo na criação)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveQrCode();
    });
  }

  Future<void> _saveQrCode() async {
    try {
      print('🔄 Iniciando salvamento do QR code para o grupo ${widget.group.id}');
      print('   📱 QR Code Data: $qrCodeData');
      
      // Validar se o grupo tem ID
      if (widget.group.id == null || widget.group.id!.isEmpty) {
        print('❌ Erro: Grupo não tem ID válido!');
        print('   🔍 Group: ${widget.group.toString()}');
        return;
      }
      
      // Se o grupo já tem QR code, não precisamos salvar novamente
      if (widget.group.qrCode != null && widget.group.qrCode!.isNotEmpty) {
        print('✅ Grupo já tem QR code salvo: ${widget.group.qrCode}');
        return;
      }
      
      final saveQrCode = ref.read(saveGroupQrCodeProvider);
      
      print('   💾 Chamando saveGroupQrCode...');
      await saveQrCode(widget.group.id!, qrCodeData);
      
      print('✅ QR code salvo com sucesso para o grupo ${widget.group.id}');
    } catch (e) {
      print('❌ Erro ao salvar QR code: $e');
      print('   Stack trace: ${StackTrace.current}');
      
      // Não mostrar erro ao usuário, pois o QR code visual ainda funciona
      // O importante é que a funcionalidade visual esteja ok
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.mainLayout, (route) => false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Column(
          children: [
            const SizedBox(height: Gaps.xs),

            // Group photo with rounded corners (not circle)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                color: BrandColors.bg2,
                image: widget.group.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.group.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.group.photoUrl == null
                  ? const Icon(Icons.group, size: 60, color: BrandColors.text2)
                  : null,
            ),

            const SizedBox(height: Gaps.lg),

            // Title
            Text(
              'Group Created',
              style: AppText.dropdownTitle.copyWith(color: BrandColors.text1),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Gaps.xs),

            // Subtitle with group name (no quotes, name in text1)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                children: [
                  const TextSpan(text: 'Invite people to join '),
                  TextSpan(
                    text: widget.group.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Gaps.xl),

            // Share link section
            _ShareLinkSection(
              linkUrl: qrCodeData,
              onCopyLink: () {
                Clipboard.setData(
                  ClipboardData(text: qrCodeData),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Link copied to clipboard'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              onShareLink: () async {
                final shareText = 'Join my group "${widget.group.name}" on Lazzo!\n\n$qrCodeData';
                
                try {
                  await Share.share(
                    shareText,
                    subject: 'Join ${widget.group.name} on Lazzo',
                  );
                } catch (e) {
                  // Fallback if share fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to share. Link copied to clipboard instead.'),
                      ),
                    );
                    Clipboard.setData(ClipboardData(text: qrCodeData));
                  }
                }
              },
            ),

            const SizedBox(height: Gaps.lg),

            // QR Code section (square)
            _QrCodeSection(data: qrCodeData),
          ],
        ),
      ),
    );
  }
}

class _ShareLinkSection extends StatelessWidget {
  final String linkUrl;
  final VoidCallback onCopyLink;
  final VoidCallback onShareLink;

  const _ShareLinkSection({
    required this.linkUrl,
    required this.onCopyLink,
    required this.onShareLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          // Link icon
          const Icon(
            Icons.insert_link,
            size: IconSizes.lg,
            color: BrandColors.text1,
          ),

          const SizedBox(width: Gaps.md),

          // Link text and expiry
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linkUrl,
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Expires in 48h',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ],
            ),
          ),

          const SizedBox(width: Gaps.md),

          // Copy button (bg3)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onCopyLink,
                child: const Icon(
                  Icons.copy,
                  size: IconSizes.sm,
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),

          const SizedBox(width: Gaps.xs),

          // Share button (green)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.planning,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onShareLink,
                child: const Icon(
                  Icons.share,
                  size: IconSizes.sm,
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodeSection extends StatelessWidget {
  final String data;

  const _QrCodeSection({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          children: [
            Text(
              'QR Code',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
            ),
            const SizedBox(height: Gaps.sm),
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'Members can scan this QR code to join your group',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
