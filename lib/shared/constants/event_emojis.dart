/// Event emoji constants and default categories
/// This is the single source of truth for emoji definitions in the app
library;

/// Default emojis commonly used for events
class EventEmojis {
  EventEmojis._(); // Private constructor to prevent instantiation

  /// Most popular event emojis shown first (defaults section)
  static const List<String> defaults = [
    // Celebration & Party
    '🎉', '🎊', '🎈', '🥳', '🎂', '🍰', '🎁', '🎭',
    
    // Food & Drink
    '🍕', '🍔', '🍟', '🌮', '🍜', '🍣', '🍝', '☕',
    
    // Activities & Sports
    '⚽', '🏀', '🎾', '🏐', '🏈', '⛳', '🎱', '🏓',
    
    // Entertainment
    '🎬', '🎮', '🎸', '🎤', '🎧', '📚', '🎨', '🎪',
    
    // Travel & Places
    '🏖️', '⛰️', '🏔️', '🏕️', '🗺️', '✈️', '🚗', '🏠',
    
    // Nature
    '🌞', '🌙', '⭐', '🌈', '🌸', '🌺', '🌻', '🌳',
  ];

  /// Celebration & Party category
  static const List<String> celebration = [
    '🎉', '🎊', '🎈', '🥳', '🎂', '🍰', '🎁', '🎭',
    '🎪', '🎨', '🎬', '🎤', '🎧', '🎸', '🎹', '🎺',
    '🎻', '🥁', '🎷', '🎮', '🎯', '🎲', '🎰', '🧩',
  ];

  /// Food & Drink category
  static const List<String> foodAndDrink = [
    '🍕', '🍔', '🍟', '🌮', '🌯', '🥙', '🥪', '🍖',
    '🍗', '🥩', '🥓', '🍳', '🥞', '🧇', '🥯', '🍞',
    '🥖', '🥨', '🧀', '🍗', '🍜', '🍝', '🍲', '🍱',
    '🍣', '🍤', '🍙', '🍚', '🍛', '☕', '🍵', '🍷',
    '🍺', '🍻', '🥂', '🍾', '🧃', '🥤', '🧋', '🍹',
  ];

  /// Activities & Sports category
  static const List<String> activities = [
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
    '🥏', '🎱', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏',
    '⛳', '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽',
    '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂',
  ];

  /// Travel & Places category
  static const List<String> travel = [
    '🏖️', '🏝️', '🏔️', '⛰️', '🏕️', '🗻', '🏞️', '🏜️',
    '🏛️', '🏗️', '🏘️', '🏚️', '🏠', '🏡', '🏢', '🏣',
    '✈️', '🛫', '🛬', '🚁', '🚂', '🚃', '🚄', '🚅',
    '🚆', '🚇', '🚈', '🚉', '🚊', '🚝', '🚞', '🚋',
    '🚌', '🚍', '🚎', '🚐', '🚑', '🚒', '🚓', '🚔',
    '🚕', '🚖', '🚗', '🚘', '🚙', '🚚', '🚛', '🚜',
    '🗺️', '🧭', '⛰️', '🏔️', '🗻', '🏕️', '⛺', '🏖️',
  ];

  /// Entertainment category
  static const List<String> entertainment = [
    '🎬', '🎭', '🎪', '🎨', '🎤', '🎧', '🎸', '🎹',
    '🎺', '🎻', '🥁', '🎷', '🎮', '🎯', '🎲', '🎰',
    '🧩', '♟️', '🎱', '🎳', '📚', '📖', '📝', '✏️',
    '🖊️', '🖍️', '🖌️', '🎨', '🖼️', '🧵', '🧶', '📷',
  ];

  /// Nature & Weather category
  static const List<String> nature = [
    '🌞', '🌝', '🌛', '🌜', '🌚', '🌕', '🌖', '🌗',
    '🌘', '🌑', '🌒', '🌓', '🌔', '🌙', '🌎', '🌍',
    '🌏', '⭐', '🌟', '✨', '⚡', '☄️', '💫', '🔥',
    '💧', '🌊', '☀️', '🌤️', '⛅', '🌥️', '☁️', '🌦️',
    '🌧️', '⛈️', '🌩️', '🌨️', '❄️', '☃️', '⛄', '🌬️',
    '🌈', '🌂', '☂️', '🌸', '🌺', '🌻', '🌷', '🌹',
    '🌿', '🍀', '🌱', '🌳', '🌲', '🌴', '🌵', '🎋',
  ];

  /// Smileys & People category
  static const List<String> smileys = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
    '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
    '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
    '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏',
  ];

  /// Gestures & Hands category
  static const List<String> gestures = [
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏',
    '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉',
    '👆', '🖕', '👇', '☝️', '🫵', '👍', '👎', '👊',
    '✊', '🤛', '🤜', '👏', '🙌', '🫶', '👐', '🤲',
  ];

  /// Objects & Technology category
  static const List<String> objects = [
    '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️',
    '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹',
    '🎥', '📽️', '🎞️', '📞', '☎️', '📟', '📠', '📺',
    '📻', '🎙️', '🎚️', '🎛️', '🧭', '⏱️', '⏲️', '⏰',
  ];

  /// Flags category (European countries + common destinations)
  static const List<String> flags = [
    '🇵🇹', // Portugal
    '🇪🇸', // Spain
    '🇫🇷', // France
    '🇮🇹', // Italy
    '🇩🇪', // Germany
    '🇬🇧', // United Kingdom
    '🇳🇱', // Netherlands
    '🇧🇪', // Belgium
    '🇨🇭', // Switzerland
    '🇦🇹', // Austria
    '🇵🇱', // Poland
    '🇨🇿', // Czech Republic
    '🇷🇴', // Romania
    '🇬🇷', // Greece
    '🇸🇮', // Slovenia
    '🇸🇪', // Sweden
    '🇳🇴', // Norway
    '🇩🇰', // Denmark
    '🇫🇮', // Finland
    '🇮🇪', // Ireland
    '🇺🇸', // United States
    '🇨🇦', // Canada
    '🇧🇷', // Brazil
    '🇦🇷', // Argentina
    '🇲🇽', // Mexico
    '🇯🇵', // Japan
    '🇰🇷', // South Korea
    '🇨🇳', // China
    '🇮🇳', // India
    '🇦🇺', // Australia
    '🇿🇦', // South Africa
    '🇪🇬', // Egypt
  ];

  /// All category definitions (excluding defaults and recents)
  static const Map<String, List<String>> categories = {
    'celebration': celebration,
    'food': foodAndDrink,
    'activities': activities,
    'travel': travel,
    'entertainment': entertainment,
    'nature': nature,
    'smileys': smileys,
    'gestures': gestures,
    'objects': objects,
    'flags': flags,
  };
}
