import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Pixel-perfect vector icons matching redesign/tech4all_ai_redesign.html exactly.
/// Using embedded SVG strings guarantees zero font-dependency or icon tree-shaking issues.
class RedesignIcons {
  RedesignIcons._();

  /// Send message upward arrow with shaft and chevron
  static Widget send({double size = 22, Color color = Colors.white}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="12" y1="19" x2="12" y2="5"></line>
        <polyline points="6 11 12 5 18 11"></polyline>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Camera with plus badge
  static Widget camera({double size = 21, Color color = const Color(0xFFBEB8B2)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M20 6h-3.17L15 4H9L7.17 6H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm-8 13c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.65 0-3 1.35-3 3s1.35 3 3 3 3-1.35 3-3-1.35-3-3-3z"/>
        <path d="M5 3H3V1H1v2H-1v2h2v2h2V5h2V3z" transform="translate(2, 1) scale(0.85)"/>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Gallery photo library stack
  static Widget gallery({double size = 20, Color color = const Color(0xFFBEB8B2)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M22 16V4c0-1.1-.9-2-2-2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2zm-11-4l2.03 2.71L16 11l4 5H8l3-4zM2 6v14c0 1.1.9 2 2 2h14v-2H4V6H2z"/>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Thumbs up outline or filled
  static Widget thumbUp({double size = 17, bool isLiked = false, Color? color}) {
    final effectiveColor = color ?? (isLiked ? const Color(0xFFFF9838) : const Color(0xFFD8CFC8));
    if (isLiked) {
      return SvgPicture.string(
        '''<svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/>
        </svg>''',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      );
    }
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
        <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }

  /// Share response curved arrow
  static Widget share({double size = 17, Color color = const Color(0xFFD8CFC8)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 17 20 12 15 7"></polyline>
        <path d="M4 18v-2a4 4 0 0 1 4-4h12"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Copy response document sheets
  static Widget copy({double size = 16, Color color = const Color(0xFFFF9333)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
        <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
        <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Top history counter-clockwise clock
  static Widget history({double size = 17, Color color = const Color(0xD9FFFFFF)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
        <path d="M3 3v5h5"></path>
        <polyline points="12 7 12 12 15 15"></polyline>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Back arrow
  static Widget arrowBack({double size = 21, Color color = Colors.white}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Settings gear
  static Widget settings({double size = 22, Color color = const Color(0xFFD4CFC9)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 c0.05,0.24,0.24,0.41,0.48,0.41h3.84c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6S13.98,15.6,12,15.6z"/>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// AI 4-pointed Sparkle Stars
  static Widget aiSparkles({double size = 21, Color color = Colors.white}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M11.5 2C11.5 7.2 7.2 11.5 2 11.5C7.2 11.5 11.5 15.8 11.5 21C11.5 15.8 15.8 11.5 21 11.5C15.8 11.5 11.5 7.2 11.5 2Z" />
        <path d="M19 2C19 4.2 17.2 6 15 6C17.2 6 19 7.8 19 10C19 7.8 20.8 6 23 6C20.8 6 19 4.2 19 2Z" />
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Lightning bolt
  static Widget lightning({double size = 15, Color color = const Color(0xFFF5923E)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="currentColor">
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Close 'X'
  static Widget close({double size = 18, Color color = Colors.white70}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Plus '+'
  static Widget plus({double size = 20, Color color = Colors.white}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
        <line x1="12" y1="5" x2="12" y2="19"></line>
        <line x1="5" y1="12" x2="19" y2="12"></line>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Search magnifying glass
  static Widget search({double size = 18, Color color = const Color(0xFF8E857D)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Edit / Rename pen
  static Widget edit({double size = 17, Color color = const Color(0xFFFF9838)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Delete / Trash can
  static Widget trash({double size = 17, Color color = Colors.redAccent}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="3 6 5 6 21 6"></polyline>
        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
        <line x1="10" y1="11" x2="10" y2="17"></line>
        <line x1="14" y1="11" x2="14" y2="17"></line>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Calendar / Plan chip
  static Widget plan({double size = 17, Color color = const Color(0xFFF5923E)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="4" width="18" height="18" rx="3" ry="3"></rect>
        <line x1="16" y1="2" x2="16" y2="6"></line>
        <line x1="8" y1="2" x2="8" y2="6"></line>
        <line x1="3" y1="10" x2="21" y2="10"></line>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Email chip
  static Widget email({double size = 17, Color color = const Color(0xFFF5923E)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="4" width="20" height="16" rx="3"></rect>
        <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Code / Terminal chip
  static Widget code({double size = 17, Color color = const Color(0xFFF5923E)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="16 18 22 12 16 6"></polyline>
        <polyline points="8 6 2 12 8 18"></polyline>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Chat bubble icon for thread items
  static Widget chatBubble({double size = 16, Color color = const Color(0xFFFF9233)}) {
    return SvgPicture.string(
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
      </svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
