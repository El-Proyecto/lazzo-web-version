import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/info_tile.dart';
import '../common/notify_row.dart';
import '../common/link_tile.dart';
import '../editor_tiles/editable_text_tile.dart';
import '../editor_tiles/editable_birthdate_tile.dart';
//import '../common/link_tile.dart';



class CreateProfileForm extends StatelessWidget {
  const CreateProfileForm({
    super.key,
    // dados
    this.phoneNumber,
    this.name,
    this.city,
    this.birthDate,
    this.notifyBirthday = false,

    // toques nos tiles
    this.onAddPhoto,
    this.onEditPhone,
    this.onEditName,
    this.onEditCity,
    this.onEditBirthDate,
    this.onToggleNotifyBirthday,

    // editores inline adicionais (legado/extra)
    this.phoneEditor,
    this.cityEditor,
    this.birthDateEditor,

    // Nome inline
    this.isEditingName = false,
    this.onCancelEditName,
    this.onSaveEditName,

    // City inline
    this.isEditingCity = false,
    this.onCancelEditCity,
    this.onSaveEditCity,

    // BirthDate inline
    this.isEditingBirthDate = false,
    this.onCancelEditBirthDate,
    this.onSaveEditBirthDate,

    // Redes – valores
    this.instagram,
    this.tiktok,
    this.spotify,

    // Redes – flags/callbacks
    this.isEditingInstagram = false,
    this.isEditingTikTok = false,
    this.isEditingSpotify = false,
    this.onEditInstagram,
    this.onEditTikTok,
    this.onEditSpotify,
    this.onCancelEditInstagram,
    this.onCancelEditTikTok,
    this.onCancelEditSpotify,
    this.onSaveEditInstagram,
    this.onSaveEditTikTok,
    this.onSaveEditSpotify,
  });

  // ---- Dados base ----
  final String? phoneNumber;
  final String? name;
  final String? city;
  final DateTime? birthDate;
  final bool notifyBirthday;

  // ---- Actions gerais ----
  final VoidCallback? onAddPhoto;
  final VoidCallback? onEditPhone;
  final VoidCallback? onEditName;
  final VoidCallback? onEditCity;
  final VoidCallback? onEditBirthDate;
  final ValueChanged<bool>? onToggleNotifyBirthday;

  // ---- Editores inline extras ----
  final Widget? phoneEditor;
  final Widget? cityEditor;
  final Widget? birthDateEditor;

  // ---- Name ----
  final bool isEditingName;
  final VoidCallback? onCancelEditName;
  final ValueChanged<String>? onSaveEditName;

  // ---- City ----
  final bool isEditingCity;
  final VoidCallback? onCancelEditCity;
  final ValueChanged<String>? onSaveEditCity;

  // ---- Birth Date ----
  final bool isEditingBirthDate;
  final VoidCallback? onCancelEditBirthDate;
  final ValueChanged<DateTime>? onSaveEditBirthDate;

  // ---- Redes (valores) ----
  final String? instagram;
  final String? tiktok;
  final String? spotify;

  // ---- Redes (edição) ----
  final bool isEditingInstagram;
  final bool isEditingTikTok;
  final bool isEditingSpotify;

  final VoidCallback? onEditInstagram;
  final VoidCallback? onEditTikTok;
  final VoidCallback? onEditSpotify;

  final VoidCallback? onCancelEditInstagram;
  final VoidCallback? onCancelEditTikTok;
  final VoidCallback? onCancelEditSpotify;

  final ValueChanged<String>? onSaveEditInstagram;
  final ValueChanged<String>? onSaveEditTikTok;
  final ValueChanged<String>? onSaveEditSpotify;

  @override
  Widget build(BuildContext context) {
    final String phone =
        (phoneNumber?.trim().isNotEmpty ?? false) ? phoneNumber!.trim() : 'Tap to Add';
    final String displayName =
        (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'Tap to Add';
    final String displayCity =
        (city?.trim().isNotEmpty ?? false) ? city!.trim() : 'Tap to Add';

    // Links
    final String displayInstagram =
        (instagram?.trim().isNotEmpty ?? false) ? instagram!.trim() : 'Tap to Add';
    final String displayTikTok =
        (tiktok?.trim().isNotEmpty ?? false) ? tiktok!.trim() : 'Tap to Add';
    final String displaySpotify =
        (spotify?.trim().isNotEmpty ?? false) ? spotify!.trim() : 'Tap to Add';

    return Container(
      width: 370,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Add Photo
          SizedBox(
            width: 116.63,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onAddPhoto,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(58),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_a_photo, size: 32, color: Color(0xFFA5A5A5)),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 116.63,
                  child: Text(
                    'Add Photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                      letterSpacing: 0.50,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Campos principais
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                background: const Color(0xFF1E1E1E),
                label: 'Phone Number',
                value: phone,
                onTap: onEditPhone,
              ),
              if (phoneEditor != null) phoneEditor!,
              const SizedBox(height: 8),

              EditableTextTile(
                label: 'Name',
                requiredAsterisk: true,
                value: displayName == 'Tap to Add' ? '' : displayName,
                isEditing: isEditingName,
                onTap: onEditName,
                onCancel: onCancelEditName,
                onSave: onSaveEditName,
                hintText: 'Enter your name...',
              ),
              const SizedBox(height: 8),

              EditableTextTile(
                label: 'City',
                requiredAsterisk: false,
                value: displayCity == 'Tap to Add' ? '' : displayCity,
                isEditing: isEditingCity,
                onTap: onEditCity,
                onCancel: onCancelEditCity,
                onSave: onSaveEditCity,
                hintText: 'Enter your city...',
              ),
              const SizedBox(height: 8),

              EditableBirthDateTile(
                value: birthDate,
                isEditing: isEditingBirthDate,
                onTap: onEditBirthDate,
                onCancel: onCancelEditBirthDate,
                onSave: onSaveEditBirthDate,
              ),
              const SizedBox(height: 8),

              NotifyRow(
                text: 'Let friends get notified when it’s my birthday',
                value: notifyBirthday,
                onChanged: onToggleNotifyBirthday,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Links
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(
                width: 70.57,
                child: Text(
                  'Links',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),

          // Instagram
          LinkTile(
            icon: FontAwesomeIcons.instagram,
            label: 'Instagram',
            value: displayInstagram,
            onTap: onEditInstagram,
            isEditing: isEditingInstagram,
            onCancelEdit: onCancelEditInstagram,
            onSaveEdit: onSaveEditInstagram,
            hintText: 'https://instagram.com/username',
          ),
          const SizedBox(height: 8),

          // TikTok
          LinkTile(
            icon: FontAwesomeIcons.tiktok,
            label: 'TikTok',
            value: displayTikTok,
            onTap: onEditTikTok,
            isEditing: isEditingTikTok,
            onCancelEdit: onCancelEditTikTok,
            onSaveEdit: onSaveEditTikTok,
            hintText: 'https://www.tiktok.com/@username',
          ),
          const SizedBox(height: 8),

          // Spotify
          LinkTile(
            icon: FontAwesomeIcons.spotify,
            label: 'Spotify',
            value: displaySpotify,
            onTap: onEditSpotify,
            isEditing: isEditingSpotify,
            onCancelEdit: onCancelEditSpotify,
            onSaveEdit: onSaveEditSpotify,
            hintText: 'https://open.spotify.com/user/your-id',
          ),
        ],
      ),
    );
  }
}
