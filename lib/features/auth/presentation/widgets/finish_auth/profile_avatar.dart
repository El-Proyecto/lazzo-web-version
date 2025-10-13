import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avatar do perfil com suporte a bucket privado:
/// - Se [photoUrl] for fornecido, usa-o diretamente.
/// - Caso contrário, se [storagePath] for fornecido, gera um Signed URL do bucket [bucketName].
/// - Se nada for fornecido, mostra placeholder (ou iniciais).
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.storagePath, // ← caminho no Storage (ex.: "<uid>/avatar_123.webp")
    this.bucketName = 'avatars', // ← o teu bucket privado
    this.signedUrlTtlSeconds = 3600, // 1h por defeito
    this.nameForInitials,
    this.onTap,
    this.size = 116,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.placeholderColor = const Color(0xFFA5A5A5),
    this.placeholderIcon = Icons.add_a_photo,
    this.borderRadius, // se null, círculo
  });

  final String? photoUrl;
  final String? storagePath;
  final String bucketName;
  final int signedUrlTtlSeconds;

  final String? nameForInitials;
  final VoidCallback? onTap;

  final double size;
  final Color backgroundColor;
  final Color placeholderColor;
  final IconData placeholderIcon;
  final double? borderRadius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _resolvedUrl; // Signed URL gerado a partir do storagePath
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _maybeResolveUrl();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o caminho no storage ou a photoUrl alterarem, volta a resolver
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.photoUrl != widget.photoUrl) {
      _maybeResolveUrl();
    }
  }

  Future<void> _maybeResolveUrl() async {
    // Se vier URL pública, usa-a tal e qual
    if ((widget.photoUrl ?? '').isNotEmpty) {
      setState(() => _resolvedUrl = widget.photoUrl);
      return;
    }
    // Se vier storagePath (bucket privado), cria signed URL
    if ((widget.storagePath ?? '').isNotEmpty) {
      await _loadSignedUrl();
      return;
    }
    // Sem nada -> placeholder
    setState(() => _resolvedUrl = null);
  }

  Future<void> _loadSignedUrl() async {
    if ((widget.storagePath ?? '').isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final bucket = Supabase.instance.client.storage.from(widget.bucketName);

      // Em supabase-dart v2.x isto devolve diretamente uma String (Signed URL).
      final dynamic signed = await bucket.createSignedUrl(
        widget.storagePath!,
        widget.signedUrlTtlSeconds,
      );

      // Se for String (v2.x), usa diretamente; se numa versão antiga vier como objeto com 'signedUrl',
      // tenta aceder a essa propriedade de forma dinâmica.
      final String? url =
          signed is String ? signed : (signed as dynamic).signedUrl as String?;

      setState(() => _resolvedUrl = url);
    } catch (e) {
      debugPrint('Erro a criar Signed URL: $e');
      setState(() => _resolvedUrl = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius ?? widget.size / 2;
    final initials = _initials(widget.nameForInitials);

    Widget placeholder() {
      if (initials.isNotEmpty) {
        return Text(
          initials,
          style: const TextStyle(
            color: Color(0xFFF2F2F2),
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        );
      }
      return Icon(
        widget.placeholderIcon,
        color: widget.placeholderColor,
        size: 32,
      );
    }

    Widget content;
    if (_isLoading) {
      content = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFA5A5A5),
        ),
      );
    } else if ((_resolvedUrl ?? '').isNotEmpty) {
      content = Image.network(
        _resolvedUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(child: placeholder()),
      );
    } else {
      content = Center(child: placeholder());
    }

    return Semantics(
      label: 'Profile photo',
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress:
            _loadSignedUrl, // long-press para refazer o signed URL (se expirar)
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(r),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }
}
