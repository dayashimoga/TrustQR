/// Cyber-Precision glassmorphic design tokens, widgets, accessibility, and localizations.
library qr_design_system;

export 'src/tokens/cyber_colors.dart';
export 'src/tokens/cyber_tokens.dart';
export 'src/tokens/cyber_typography.dart';
export 'src/tokens/cyber_theme.dart';
export 'src/glass/cyber_glass_card.dart';
export 'src/glass/cyber_glass_sheet.dart';
export 'src/reticle/hud_scanner_reticle.dart';
export 'src/widgets/cyber_button.dart';
export 'src/widgets/cyber_badge.dart';
export 'src/widgets/threat_score_gauge.dart';
export 'src/widgets/trust_qr_badge.dart';
export 'src/layout/responsive_layout.dart';
export 'src/layout/adaptive_workspace_shell.dart';
export 'src/accessibility/cyber_accessibility.dart';
export 'src/l10n/cyber_localizations.dart';

// Backward compatibility aliases
export 'src/glass/cyber_glass_card.dart' show CyberGlassCard;

import 'src/glass/cyber_glass_card.dart';

/// Legacy alias for [CyberGlassCard].
typedef GlassmorphicCard = CyberGlassCard;
