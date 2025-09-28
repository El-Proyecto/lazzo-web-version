// Shared Components Exports
// This file exports only truly reusable shared components
// Feature-specific components are now located in their respective feature folders

// NAVIGATION COMPONENTS (Truly Shared)
export 'nav/common_app_bar.dart'; // NEW: Replaces 3 feature-specific AppBars
export 'nav/navigation_bar.dart'; // App-wide bottom navigation

// CARD COMPONENTS (Truly Shared)
export 'cards/base_card.dart'; // NEW: Generic card foundation
export 'cards/memory_card.dart'; // Used in profile, details
export 'cards/memory_summary_card.dart'; // Used in home, profile
export 'cards/group_card.dart'; // Used in groups, selections
export 'cards/pending_event_card.dart'; // Used in home, notifications
export 'cards/pending_event_expanded_card.dart'; // Expanded version

// BUTTON COMPONENTS (Truly Shared)
export 'buttons/vote_widget.dart'; // NEW: Replaces 14 voting buttons
export 'buttons/green_button.dart'; // Used across auth, create_event
export 'buttons/continue_with.dart'; // Used across auth flows
export 'buttons/expanded_card_button.dart'; // Generic expandable button
export 'buttons/stacked_avatars.dart'; // Reusable avatar display

// INPUT COMPONENTS (Truly Shared)
export 'inputs/inputBox.dart'; // Generic input field
export 'inputs/search_bar.dart'; // Generic search component

// LAYOUT & STRUCTURE (Truly Shared)
export 'sections/section_header.dart'; // Generic section title
export 'sections/section_block.dart'; // Generic section wrapper
export 'sections/lazzo_header.dart'; // App branding (used across auth)

// UTILITY COMPONENTS (Truly Shared)
export 'widgets/grabber_bar.dart'; // Generic sheet handle
export 'badges/group_badge.dart'; // Reusable badge component
export 'chips/filter_chip.dart'; // Generic filter UI
