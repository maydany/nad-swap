# Design System Package

## package-meta.yaml
```yaml
schema_version: "1.0"
package_name: "uniswap-core-surfaces-design-system"
generated_at: "2026-02-15T15:36:50Z"
source:
  type: "mixed"
  value: "https://app.uniswap.org/ + https://app.uniswap.org/assets/index-DXaJfaQ2.js + https://unpkg.com/@uniswap/widgets@2.59.0/dist/fonts.css"
tailwind_target: "v4"
match_strategy: "strict"
modes:
  - "dark"
component_generation_defaults:
  source_of_truth_files:
    - "design-system.json"
    - "component-blueprints.json"
  token_policy:
    rename_forbidden: true
    silent_token_creation_forbidden: true
  missing_token_report:
    required: true
    section_name: "Missing Token Report"
confidence:
  overall: 0.87
  notes:
    - "Core dark-theme color, breakpoint, radius, and motion values are directly observed in production bundle constants."
    - "Scale interpolation and semantic role layering are inferred for reusable token ramps."
```

## design-system.json
```json
{
  "meta": {
    "name": "uniswap-core-surfaces",
    "tailwindTarget": "v4",
    "modes": [
      "dark"
    ],
    "matchStrategy": "strict"
  },
  "tokens": {
    "color": {
      "primary": {
        "50": "#FFE8F8",
        "100": "#FFD1F1",
        "200": "#FFB3E8",
        "300": "#FF8CDB",
        "400": "#FF63CE",
        "500": "#FF37C7",
        "600": "#E500A5",
        "700": "#B80084",
        "800": "#8A0063",
        "900": "#5A003F"
      },
      "secondary": {
        "100": "#FFFFFFD9",
        "200": "#FFFFFFA6",
        "300": "#FFFFFF94",
        "400": "#FFFFFF61",
        "500": "#FFFFFF1F",
        "600": "#FFFFFF14",
        "700": "#0000000F",
        "800": "#0000000A",
        "900": "#00000000"
      },
      "accent": {
        "100": "#D0D9F8",
        "200": "#4C82FB",
        "300": "#4981FF",
        "400": "#23A3FF",
        "500": "#0052FF",
        "600": "#0047FF",
        "700": "#10143D",
        "800": "#040E34",
        "900": "#02071A"
      },
      "neutral": {
        "0": "#FFFFFF",
        "50": "#FCFCFC",
        "100": "#F5F5F5",
        "200": "#D9D9D9",
        "300": "#B3B3B3",
        "400": "#8C8C8C",
        "500": "#666666",
        "600": "#393939",
        "700": "#2F2F2F",
        "800": "#242424",
        "900": "#1F1F1F",
        "950": "#131313"
      },
      "success": {
        "100": "#093A16",
        "300": "#15863C",
        "500": "#21C95E",
        "700": "#0C8911"
      },
      "warning": {
        "100": "#7A5801",
        "300": "#996F01",
        "500": "#FFBF17",
        "700": "#FFDD0D"
      },
      "danger": {
        "100": "#BF0D0D",
        "300": "#E10F0F",
        "500": "#FF593C",
        "700": "#FF401F"
      }
    },
    "semantic": {
      "bg": {
        "base": "color.neutral.950",
        "raised": "color.neutral.900",
        "muted": "color.neutral.800",
        "subtle": "color.secondary.500",
        "overlay": "color.secondary.600",
        "scrim": "#00000099"
      },
      "text": {
        "primary": "color.neutral.0",
        "secondary": "color.secondary.200",
        "tertiary": "color.secondary.400",
        "inverse": "color.neutral.950",
        "onAccent": "color.neutral.0"
      },
      "border": {
        "default": "color.secondary.500",
        "muted": "color.secondary.600",
        "strong": "color.secondary.400",
        "focus": "color.primary.500"
      },
      "action": {
        "primary": "color.primary.500",
        "primaryHover": "color.primary.600",
        "secondary": "color.secondary.500",
        "secondaryHover": "color.secondary.400",
        "danger": "color.danger.500",
        "dangerHover": "color.danger.700",
        "success": "color.success.500",
        "warning": "color.warning.500"
      }
    },
    "typography": {
      "fontFamily": {
        "sans": [
          "Basel",
          "Inter",
          "-apple-system",
          "BlinkMacSystemFont",
          "sans-serif"
        ],
        "sansVariable": [
          "Basel",
          "InterVariable",
          "Inter",
          "sans-serif"
        ],
        "mono": [
          "IBM Plex Mono",
          "ui-monospace",
          "SFMono-Regular",
          "monospace"
        ]
      },
      "fontSize": {
        "xs": {
          "size": "12px",
          "lineHeight": "16px",
          "letterSpacing": "0",
          "weight": 485
        },
        "sm": {
          "size": "14px",
          "lineHeight": "20px",
          "letterSpacing": "0",
          "weight": 485
        },
        "base": {
          "size": "16px",
          "lineHeight": "24px",
          "letterSpacing": "0",
          "weight": 485
        },
        "lg": {
          "size": "18px",
          "lineHeight": "26px",
          "letterSpacing": "0",
          "weight": 535
        },
        "xl": {
          "size": "20px",
          "lineHeight": "30px",
          "letterSpacing": "-0.01em",
          "weight": 535
        },
        "2xl": {
          "size": "24px",
          "lineHeight": "34px",
          "letterSpacing": "-0.015em",
          "weight": 535
        }
      },
      "fontWeight": {
        "book": 485,
        "medium": 535,
        "semibold": 600,
        "bold": 700
      }
    },
    "spacing": {
      "0": "0px",
      "1": "4px",
      "2": "8px",
      "3": "12px",
      "4": "16px",
      "5": "20px",
      "6": "24px",
      "7": "28px",
      "8": "32px",
      "10": "40px",
      "12": "48px",
      "14": "56px",
      "16": "64px"
    },
    "radius": {
      "none": "0px",
      "xs": "4px",
      "sm": "6px",
      "md": "8px",
      "lg": "12px",
      "xl": "16px",
      "2xl": "20px",
      "3xl": "24px",
      "4xl": "32px",
      "full": "999999px"
    },
    "shadow": {
      "sm": "0px 0px 10px 0px rgba(34, 34, 34, 0.04)",
      "md": "4px 4px 8px rgba(0, 0, 0, 0.32)",
      "lg": "12px 16px 24px rgba(0, 0, 0, 0.24), 12px 8px 12px rgba(0, 0, 0, 0.24), 4px 4px 8px rgba(0, 0, 0, 0.32)"
    },
    "borderWidth": {
      "DEFAULT": "1px",
      "2": "2px"
    },
    "motion": {
      "duration": {
        "fast": "125ms",
        "base": "250ms",
        "slow": "500ms"
      },
      "easing": {
        "ease": "ease",
        "in": "ease-in",
        "out": "ease-out",
        "inOut": "ease-in-out",
        "stiff": "cubic-bezier(0.17, 0.67, 0.45, 1)",
        "quick": "cubic-bezier(0.25, 0.46, 0.45, 0.94)",
        "bouncy": "cubic-bezier(0.34, 1.56, 0.64, 1)"
      }
    },
    "breakpoints": {
      "xxs": "360px",
      "xs": "380px",
      "sm": "450px",
      "md": "640px",
      "lg": "768px",
      "xl": "1024px",
      "2xl": "1280px",
      "3xl": "1536px"
    },
    "container": {
      "maxWidth": {
        "base": "1200px",
        "lg": "1280px",
        "xl": "1536px"
      },
      "paddingInline": "24px"
    }
  },
  "evidence": {
    "observed": [
      "app.uniswap.org index HTML preloads Basel-Grotesk Book/Medium and sets global font-family to Basel.",
      "Production token object includes dark neutral/surface colors: neutral1=#FFFFFF, surface1=#131313, surface2=#1F1F1F, surface3Solid=#393939.",
      "Production token object includes light neutral/surface colors: neutral1=#131313, surface1=#FFFFFF, surface2=#F9F9F9, surface3Solid=#F2F2F2.",
      "Accent colors in production token object: accent1=#FF37C7 and accent1Hovered=#E500A5.",
      "Dark status colors observed: success=#21C95E, warning=#FFBF17, critical=#FF593C.",
      "Light status colors observed: success=#0C8911, warning=#996F01, critical=#E10F0F.",
      "Radii scale observed in production constants: 4, 6, 8, 12, 16, 20, 24, 32, full.",
      "Breakpoints observed in production constants: 360, 380, 450, 640, 768, 1024, 1280, 1536.",
      "Motion durations observed in production constants: fast=125ms, medium=250ms, slow=500ms.",
      "Transition easings observed in production constants include ease-in-out and cubic-bezier presets for stiff/quick/bouncy."
    ],
    "inferred": [
      {
        "item": "primary scale steps 50-900 around #FF37C7",
        "confidence": 0.82,
        "reason": "Only primary and hover values are directly observed; intermediate scale steps were interpolated for reusable Tailwind ramps."
      },
      {
        "item": "semantic bg/text/border/action role mapping",
        "confidence": 0.86,
        "reason": "Role mapping is inferred from token naming and swap UI patterns rather than explicit semantic groups in source."
      },
      {
        "item": "typography size ramp xs-2xl",
        "confidence": 0.77,
        "reason": "16px baseline is directly observed; the full scale is harmonized with observed 14/16/20 values and production UI density."
      },
      {
        "item": "container maxWidth and padding defaults",
        "confidence": 0.74,
        "reason": "1200px max width is observed; additional container tiers are inferred from production breakpoints."
      },
      {
        "item": "shadow token stratification sm/md/lg",
        "confidence": 0.79,
        "reason": "Observed deep/shallow shadow strings were normalized into a three-tier token system for component reuse."
      }
    ]
  }
}
```

## tailwind.preset.ts
```ts
import type { Config } from "tailwindcss";

const preset: Partial<Config> = {
  darkMode: ["class", "[data-theme='dark']"],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "var(--color-primary-50)",
          100: "var(--color-primary-100)",
          200: "var(--color-primary-200)",
          300: "var(--color-primary-300)",
          400: "var(--color-primary-400)",
          500: "var(--color-primary-500)",
          600: "var(--color-primary-600)",
          700: "var(--color-primary-700)",
          800: "var(--color-primary-800)",
          900: "var(--color-primary-900)"
        },
        secondary: {
          100: "var(--color-secondary-100)",
          200: "var(--color-secondary-200)",
          300: "var(--color-secondary-300)",
          400: "var(--color-secondary-400)",
          500: "var(--color-secondary-500)",
          600: "var(--color-secondary-600)",
          700: "var(--color-secondary-700)",
          800: "var(--color-secondary-800)",
          900: "var(--color-secondary-900)"
        },
        accent: {
          100: "var(--color-accent-100)",
          200: "var(--color-accent-200)",
          300: "var(--color-accent-300)",
          400: "var(--color-accent-400)",
          500: "var(--color-accent-500)",
          600: "var(--color-accent-600)",
          700: "var(--color-accent-700)",
          800: "var(--color-accent-800)",
          900: "var(--color-accent-900)"
        },
        neutral: {
          0: "var(--color-neutral-0)",
          50: "var(--color-neutral-50)",
          100: "var(--color-neutral-100)",
          200: "var(--color-neutral-200)",
          300: "var(--color-neutral-300)",
          400: "var(--color-neutral-400)",
          500: "var(--color-neutral-500)",
          600: "var(--color-neutral-600)",
          700: "var(--color-neutral-700)",
          800: "var(--color-neutral-800)",
          900: "var(--color-neutral-900)",
          950: "var(--color-neutral-950)"
        },
        success: {
          100: "var(--color-success-100)",
          300: "var(--color-success-300)",
          500: "var(--color-success-500)",
          700: "var(--color-success-700)"
        },
        warning: {
          100: "var(--color-warning-100)",
          300: "var(--color-warning-300)",
          500: "var(--color-warning-500)",
          700: "var(--color-warning-700)"
        },
        danger: {
          100: "var(--color-danger-100)",
          300: "var(--color-danger-300)",
          500: "var(--color-danger-500)",
          700: "var(--color-danger-700)"
        },
        semantic: {
          bgBase: "var(--semantic-bg-base)",
          bgRaised: "var(--semantic-bg-raised)",
          bgMuted: "var(--semantic-bg-muted)",
          bgSubtle: "var(--semantic-bg-subtle)",
          bgOverlay: "var(--semantic-bg-overlay)",
          bgScrim: "var(--semantic-bg-scrim)",
          textPrimary: "var(--semantic-text-primary)",
          textSecondary: "var(--semantic-text-secondary)",
          textTertiary: "var(--semantic-text-tertiary)",
          textInverse: "var(--semantic-text-inverse)",
          textOnAccent: "var(--semantic-text-on-accent)",
          borderDefault: "var(--semantic-border-default)",
          borderMuted: "var(--semantic-border-muted)",
          borderStrong: "var(--semantic-border-strong)",
          borderFocus: "var(--semantic-border-focus)",
          actionPrimary: "var(--semantic-action-primary)",
          actionPrimaryHover: "var(--semantic-action-primary-hover)",
          actionSecondary: "var(--semantic-action-secondary)",
          actionSecondaryHover: "var(--semantic-action-secondary-hover)",
          actionDanger: "var(--semantic-action-danger)",
          actionDangerHover: "var(--semantic-action-danger-hover)",
          actionSuccess: "var(--semantic-action-success)",
          actionWarning: "var(--semantic-action-warning)"
        }
      },
      fontFamily: {
        sans: ["var(--font-sans)"],
        "sans-variable": ["var(--font-sans-variable)"],
        mono: ["var(--font-mono)"]
      },
      fontSize: {
        xs: ["var(--font-size-xs)", { lineHeight: "var(--line-height-xs)", fontWeight: "var(--font-weight-book)" }],
        sm: ["var(--font-size-sm)", { lineHeight: "var(--line-height-sm)", fontWeight: "var(--font-weight-book)" }],
        base: ["var(--font-size-base)", { lineHeight: "var(--line-height-base)", fontWeight: "var(--font-weight-book)" }],
        lg: ["var(--font-size-lg)", { lineHeight: "var(--line-height-lg)", fontWeight: "var(--font-weight-medium)" }],
        xl: ["var(--font-size-xl)", { lineHeight: "var(--line-height-xl)", fontWeight: "var(--font-weight-medium)" }],
        "2xl": ["var(--font-size-2xl)", { lineHeight: "var(--line-height-2xl)", fontWeight: "var(--font-weight-medium)" }]
      },
      spacing: {
        0: "var(--space-0)",
        1: "var(--space-1)",
        2: "var(--space-2)",
        3: "var(--space-3)",
        4: "var(--space-4)",
        5: "var(--space-5)",
        6: "var(--space-6)",
        7: "var(--space-7)",
        8: "var(--space-8)",
        10: "var(--space-10)",
        12: "var(--space-12)",
        14: "var(--space-14)",
        16: "var(--space-16)"
      },
      borderRadius: {
        none: "var(--radius-none)",
        xs: "var(--radius-xs)",
        sm: "var(--radius-sm)",
        md: "var(--radius-md)",
        lg: "var(--radius-lg)",
        xl: "var(--radius-xl)",
        "2xl": "var(--radius-2xl)",
        "3xl": "var(--radius-3xl)",
        "4xl": "var(--radius-4xl)",
        full: "var(--radius-full)"
      },
      boxShadow: {
        sm: "var(--shadow-sm)",
        md: "var(--shadow-md)",
        lg: "var(--shadow-lg)"
      },
      borderWidth: {
        DEFAULT: "var(--border-width-default)",
        2: "var(--border-width-2)"
      },
      transitionDuration: {
        fast: "var(--duration-fast)",
        base: "var(--duration-base)",
        slow: "var(--duration-slow)"
      },
      transitionTimingFunction: {
        ease: "var(--easing-ease)",
        in: "var(--easing-in)",
        out: "var(--easing-out)",
        "in-out": "var(--easing-in-out)",
        stiff: "var(--easing-stiff)",
        quick: "var(--easing-quick)",
        bouncy: "var(--easing-bouncy)"
      },
      screens: {
        xxs: "var(--breakpoint-xxs)",
        xs: "var(--breakpoint-xs)",
        sm: "var(--breakpoint-sm)",
        md: "var(--breakpoint-md)",
        lg: "var(--breakpoint-lg)",
        xl: "var(--breakpoint-xl)",
        "2xl": "var(--breakpoint-2xl)",
        "3xl": "var(--breakpoint-3xl)"
      },
      maxWidth: {
        container: "var(--container-max-base)",
        "container-lg": "var(--container-max-lg)",
        "container-xl": "var(--container-max-xl)"
      }
    }
  }
};

export default preset;
```

## tokens.css
```css
:root {
  color-scheme: dark;

  --color-primary-50: #ffe8f8;
  --color-primary-100: #ffd1f1;
  --color-primary-200: #ffb3e8;
  --color-primary-300: #ff8cdb;
  --color-primary-400: #ff63ce;
  --color-primary-500: #ff37c7;
  --color-primary-600: #e500a5;
  --color-primary-700: #b80084;
  --color-primary-800: #8a0063;
  --color-primary-900: #5a003f;

  --color-secondary-100: #ffffffd9;
  --color-secondary-200: #ffffffa6;
  --color-secondary-300: #ffffff94;
  --color-secondary-400: #ffffff61;
  --color-secondary-500: #ffffff1f;
  --color-secondary-600: #ffffff14;
  --color-secondary-700: #0000000f;
  --color-secondary-800: #0000000a;
  --color-secondary-900: #00000000;

  --color-accent-100: #d0d9f8;
  --color-accent-200: #4c82fb;
  --color-accent-300: #4981ff;
  --color-accent-400: #23a3ff;
  --color-accent-500: #0052ff;
  --color-accent-600: #0047ff;
  --color-accent-700: #10143d;
  --color-accent-800: #040e34;
  --color-accent-900: #02071a;

  --color-neutral-0: #ffffff;
  --color-neutral-50: #fcfcfc;
  --color-neutral-100: #f5f5f5;
  --color-neutral-200: #d9d9d9;
  --color-neutral-300: #b3b3b3;
  --color-neutral-400: #8c8c8c;
  --color-neutral-500: #666666;
  --color-neutral-600: #393939;
  --color-neutral-700: #2f2f2f;
  --color-neutral-800: #242424;
  --color-neutral-900: #1f1f1f;
  --color-neutral-950: #131313;

  --color-success-100: #093a16;
  --color-success-300: #15863c;
  --color-success-500: #21c95e;
  --color-success-700: #0c8911;

  --color-warning-100: #7a5801;
  --color-warning-300: #996f01;
  --color-warning-500: #ffbf17;
  --color-warning-700: #ffdd0d;

  --color-danger-100: #bf0d0d;
  --color-danger-300: #e10f0f;
  --color-danger-500: #ff593c;
  --color-danger-700: #ff401f;

  --semantic-bg-base: var(--color-neutral-950);
  --semantic-bg-raised: var(--color-neutral-900);
  --semantic-bg-muted: var(--color-neutral-800);
  --semantic-bg-subtle: var(--color-secondary-500);
  --semantic-bg-overlay: var(--color-secondary-600);
  --semantic-bg-scrim: #00000099;

  --semantic-text-primary: var(--color-neutral-0);
  --semantic-text-secondary: var(--color-secondary-200);
  --semantic-text-tertiary: var(--color-secondary-400);
  --semantic-text-inverse: var(--color-neutral-950);
  --semantic-text-on-accent: var(--color-neutral-0);

  --semantic-border-default: var(--color-secondary-500);
  --semantic-border-muted: var(--color-secondary-600);
  --semantic-border-strong: var(--color-secondary-400);
  --semantic-border-focus: var(--color-primary-500);

  --semantic-action-primary: var(--color-primary-500);
  --semantic-action-primary-hover: var(--color-primary-600);
  --semantic-action-secondary: var(--color-secondary-500);
  --semantic-action-secondary-hover: var(--color-secondary-400);
  --semantic-action-danger: var(--color-danger-500);
  --semantic-action-danger-hover: var(--color-danger-700);
  --semantic-action-success: var(--color-success-500);
  --semantic-action-warning: var(--color-warning-500);

  --font-sans: "Basel", "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
  --font-sans-variable: "Basel", "InterVariable", "Inter", sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, SFMono-Regular, monospace;

  --font-size-xs: 12px;
  --font-size-sm: 14px;
  --font-size-base: 16px;
  --font-size-lg: 18px;
  --font-size-xl: 20px;
  --font-size-2xl: 24px;

  --line-height-xs: 16px;
  --line-height-sm: 20px;
  --line-height-base: 24px;
  --line-height-lg: 26px;
  --line-height-xl: 30px;
  --line-height-2xl: 34px;

  --font-weight-book: 485;
  --font-weight-medium: 535;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  --space-0: 0px;
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-7: 28px;
  --space-8: 32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-14: 56px;
  --space-16: 64px;

  --radius-none: 0px;
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-2xl: 20px;
  --radius-3xl: 24px;
  --radius-4xl: 32px;
  --radius-full: 999999px;

  --shadow-sm: 0px 0px 10px 0px rgba(34, 34, 34, 0.04);
  --shadow-md: 4px 4px 8px rgba(0, 0, 0, 0.32);
  --shadow-lg: 12px 16px 24px rgba(0, 0, 0, 0.24), 12px 8px 12px rgba(0, 0, 0, 0.24), 4px 4px 8px rgba(0, 0, 0, 0.32);

  --border-width-default: 1px;
  --border-width-2: 2px;

  --duration-fast: 125ms;
  --duration-base: 250ms;
  --duration-slow: 500ms;

  --easing-ease: ease;
  --easing-in: ease-in;
  --easing-out: ease-out;
  --easing-in-out: ease-in-out;
  --easing-stiff: cubic-bezier(0.17, 0.67, 0.45, 1);
  --easing-quick: cubic-bezier(0.25, 0.46, 0.45, 0.94);
  --easing-bouncy: cubic-bezier(0.34, 1.56, 0.64, 1);

  --breakpoint-xxs: 360px;
  --breakpoint-xs: 380px;
  --breakpoint-sm: 450px;
  --breakpoint-md: 640px;
  --breakpoint-lg: 768px;
  --breakpoint-xl: 1024px;
  --breakpoint-2xl: 1280px;
  --breakpoint-3xl: 1536px;

  --container-max-base: 1200px;
  --container-max-lg: 1280px;
  --container-max-xl: 1536px;
  --container-padding-inline: 24px;
}
```

## component-blueprints.json
```json
{
  "components": {
    "button": {
      "requiredTokenRefs": [
        "semantic.action.primary",
        "semantic.action.primaryHover",
        "semantic.action.secondary",
        "semantic.action.secondaryHover",
        "semantic.action.danger",
        "semantic.action.dangerHover",
        "semantic.text.onAccent",
        "semantic.border.focus",
        "radius.md",
        "spacing.2",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "root",
        "icon",
        "label"
      ],
      "defaultVariants": {
        "intent": "primary",
        "appearance": "solid",
        "size": "md"
      },
      "variants": {
        "intent": {
          "primary": {
            "root": "text-semantic-text-onAccent"
          },
          "secondary": {
            "root": "text-semantic-text-primary"
          },
          "danger": {
            "root": "text-semantic-text-onAccent"
          },
          "success": {
            "root": "text-semantic-text-onAccent"
          }
        },
        "appearance": {
          "solid": {
            "root": "border border-transparent"
          },
          "outline": {
            "root": "bg-transparent border border-semantic-border-default"
          },
          "ghost": {
            "root": "bg-transparent border border-transparent"
          }
        },
        "size": {
          "sm": {
            "root": "h-9 px-3 gap-2 rounded-md text-sm font-medium",
            "icon": "h-4 w-4",
            "label": "leading-5"
          },
          "md": {
            "root": "h-10 px-4 gap-2 rounded-lg text-base font-medium",
            "icon": "h-4 w-4",
            "label": "leading-6"
          },
          "lg": {
            "root": "h-12 px-5 gap-3 rounded-xl text-lg font-semibold",
            "icon": "h-5 w-5",
            "label": "leading-6"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "36px"
        },
        "md": {
          "minHeight": "40px"
        },
        "lg": {
          "minHeight": "48px"
        }
      },
      "states": {
        "default": {
          "root": "inline-flex items-center justify-center transition-colors duration-base ease-in-out"
        },
        "hover": {
          "root": "hover:opacity-95"
        },
        "active": {
          "root": "active:scale-[0.99]"
        },
        "focusVisible": {
          "root": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus focus-visible:ring-offset-2 focus-visible:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "root": "disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none"
        },
        "selected": {
          "root": "aria-pressed:ring-2 aria-pressed:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [
        {
          "when": {
            "intent": "primary",
            "appearance": "solid"
          },
          "classes": {
            "root": "bg-semantic-action-primary hover:bg-semantic-action-primaryHover"
          }
        },
        {
          "when": {
            "intent": "secondary",
            "appearance": "solid"
          },
          "classes": {
            "root": "bg-semantic-action-secondary hover:bg-semantic-action-secondaryHover"
          }
        },
        {
          "when": {
            "intent": "danger",
            "appearance": "solid"
          },
          "classes": {
            "root": "bg-semantic-action-danger hover:bg-semantic-action-dangerHover"
          }
        },
        {
          "when": {
            "intent": "success",
            "appearance": "solid"
          },
          "classes": {
            "root": "bg-semantic-action-success hover:brightness-110"
          }
        }
      ],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use a visible 2px focus ring with 3:1+ contrast against surrounding surfaces.",
        "notes": [
          "Do not rely on color alone to indicate destructive actions.",
          "Preserve disabled semantics with the native disabled attribute."
        ]
      }
    },
    "input": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "semantic.border.focus",
        "semantic.action.danger",
        "radius.lg",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "wrapper",
        "field",
        "prefix",
        "suffix",
        "message"
      ],
      "defaultVariants": {
        "size": "md",
        "tone": "default"
      },
      "variants": {
        "size": {
          "sm": {
            "wrapper": "h-10 px-3 rounded-lg",
            "field": "text-sm"
          },
          "md": {
            "wrapper": "h-12 px-4 rounded-xl",
            "field": "text-base"
          },
          "lg": {
            "wrapper": "h-14 px-4 rounded-2xl",
            "field": "text-lg"
          }
        },
        "tone": {
          "default": {
            "wrapper": "bg-semantic-bg-raised border border-semantic-border-default",
            "message": "text-semantic-text-secondary"
          },
          "error": {
            "wrapper": "bg-semantic-bg-raised border border-danger-500",
            "message": "text-danger-500"
          },
          "success": {
            "wrapper": "bg-semantic-bg-raised border border-success-500",
            "message": "text-success-500"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "40px"
        },
        "md": {
          "minHeight": "48px"
        },
        "lg": {
          "minHeight": "56px"
        }
      },
      "states": {
        "default": {
          "wrapper": "flex items-center gap-2 transition-colors duration-base ease-in-out",
          "field": "w-full bg-transparent text-semantic-text-primary placeholder:text-semantic-text-secondary focus:outline-none"
        },
        "hover": {
          "wrapper": "hover:border-semantic-border-strong"
        },
        "active": {
          "wrapper": "active:border-semantic-border-strong"
        },
        "focusVisible": {
          "wrapper": "focus-within:ring-2 focus-within:ring-semantic-border-focus focus-within:ring-offset-2 focus-within:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "wrapper": "opacity-50 pointer-events-none",
          "field": "cursor-not-allowed"
        },
        "selected": {
          "wrapper": "data-[selected=true]:border-semantic-action-primary"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use focus-within ring for grouped controls and preserve native input focus.",
        "notes": [
          "Pair with visible label and helper/error text.",
          "Use aria-invalid when tone=error."
        ]
      }
    },
    "textarea": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "semantic.border.focus",
        "radius.lg",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "wrapper",
        "field",
        "message"
      ],
      "defaultVariants": {
        "size": "md",
        "tone": "default"
      },
      "variants": {
        "size": {
          "sm": {
            "wrapper": "p-3 rounded-lg",
            "field": "min-h-20 text-sm"
          },
          "md": {
            "wrapper": "p-4 rounded-xl",
            "field": "min-h-28 text-base"
          },
          "lg": {
            "wrapper": "p-4 rounded-2xl",
            "field": "min-h-36 text-lg"
          }
        },
        "tone": {
          "default": {
            "wrapper": "bg-semantic-bg-raised border border-semantic-border-default"
          },
          "error": {
            "wrapper": "bg-semantic-bg-raised border border-danger-500"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "80px"
        },
        "md": {
          "minHeight": "112px"
        },
        "lg": {
          "minHeight": "144px"
        }
      },
      "states": {
        "default": {
          "wrapper": "transition-colors duration-base ease-in-out",
          "field": "w-full resize-y bg-transparent text-semantic-text-primary placeholder:text-semantic-text-secondary focus:outline-none"
        },
        "hover": {
          "wrapper": "hover:border-semantic-border-strong"
        },
        "active": {
          "wrapper": "active:border-semantic-border-strong"
        },
        "focusVisible": {
          "wrapper": "focus-within:ring-2 focus-within:ring-semantic-border-focus focus-within:ring-offset-2 focus-within:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "wrapper": "opacity-50 pointer-events-none"
        },
        "selected": {
          "wrapper": "data-[selected=true]:border-semantic-action-primary"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use focus-within ring and maintain sufficient contrast for placeholder text.",
        "notes": [
          "Expose character limits and validation states with aria-live messaging."
        ]
      }
    },
    "select": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "semantic.border.focus",
        "radius.lg",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "trigger",
        "value",
        "icon",
        "content",
        "item"
      ],
      "defaultVariants": {
        "size": "md",
        "tone": "default"
      },
      "variants": {
        "size": {
          "sm": {
            "trigger": "h-10 px-3 rounded-lg text-sm"
          },
          "md": {
            "trigger": "h-12 px-4 rounded-xl text-base"
          },
          "lg": {
            "trigger": "h-14 px-4 rounded-2xl text-lg"
          }
        },
        "tone": {
          "default": {
            "trigger": "bg-semantic-bg-raised border border-semantic-border-default"
          },
          "error": {
            "trigger": "bg-semantic-bg-raised border border-danger-500"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "40px"
        },
        "md": {
          "minHeight": "48px"
        },
        "lg": {
          "minHeight": "56px"
        }
      },
      "states": {
        "default": {
          "trigger": "inline-flex items-center justify-between gap-2 w-full text-semantic-text-primary",
          "content": "bg-semantic-bg-raised border border-semantic-border-default rounded-xl shadow-lg",
          "item": "px-3 py-2 rounded-lg text-semantic-text-primary"
        },
        "hover": {
          "trigger": "hover:border-semantic-border-strong",
          "item": "hover:bg-semantic-bg-muted"
        },
        "active": {
          "trigger": "active:border-semantic-border-strong",
          "item": "active:bg-semantic-bg-muted"
        },
        "focusVisible": {
          "trigger": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus focus-visible:ring-offset-2 focus-visible:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "trigger": "opacity-50 pointer-events-none"
        },
        "selected": {
          "item": "data-[state=checked]:bg-semantic-action-primary data-[state=checked]:text-semantic-text-onAccent"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Expose listbox keyboard interactions and visible active descendant indication.",
        "notes": [
          "Use aria-expanded and aria-controls on trigger.",
          "Ensure item text contrast remains 4.5:1 in selected and hover states."
        ]
      }
    },
    "card": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.bg.muted",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "radius.xl",
        "shadow.md",
        "spacing.4",
        "spacing.6"
      ],
      "slots": [
        "root",
        "header",
        "content",
        "footer"
      ],
      "defaultVariants": {
        "tone": "default",
        "elevation": "flat"
      },
      "variants": {
        "tone": {
          "default": {
            "root": "bg-semantic-bg-raised border border-semantic-border-default"
          },
          "subtle": {
            "root": "bg-semantic-bg-muted border border-semantic-border-muted"
          }
        },
        "elevation": {
          "flat": {
            "root": "shadow-none"
          },
          "floating": {
            "root": "shadow-lg"
          }
        }
      },
      "sizes": {
        "sm": {
          "padding": "16px"
        },
        "md": {
          "padding": "24px"
        },
        "lg": {
          "padding": "32px"
        }
      },
      "states": {
        "default": {
          "root": "rounded-xl p-6",
          "header": "mb-4",
          "footer": "mt-4"
        },
        "hover": {
          "root": "hover:border-semantic-border-strong"
        },
        "active": {
          "root": "active:translate-y-px"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-50 pointer-events-none"
        },
        "selected": {
          "root": "data-[selected=true]:border-semantic-action-primary"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Cards that are interactive should expose focus ring and role=button or link semantics.",
        "notes": [
          "Do not hide actionable affordances inside non-interactive card markup."
        ]
      }
    },
    "badge": {
      "requiredTokenRefs": [
        "semantic.text.onAccent",
        "semantic.text.primary",
        "semantic.action.primary",
        "semantic.action.success",
        "semantic.action.warning",
        "semantic.action.danger",
        "radius.full",
        "spacing.2",
        "spacing.3"
      ],
      "slots": [
        "root",
        "dot",
        "label"
      ],
      "defaultVariants": {
        "intent": "neutral",
        "size": "md"
      },
      "variants": {
        "intent": {
          "neutral": {
            "root": "bg-semantic-bg-muted text-semantic-text-primary"
          },
          "brand": {
            "root": "bg-semantic-action-primary text-semantic-text-onAccent"
          },
          "success": {
            "root": "bg-semantic-action-success text-semantic-text-onAccent"
          },
          "warning": {
            "root": "bg-semantic-action-warning text-neutral-950"
          },
          "danger": {
            "root": "bg-semantic-action-danger text-semantic-text-onAccent"
          }
        },
        "size": {
          "sm": {
            "root": "h-6 px-2 text-xs",
            "dot": "h-1.5 w-1.5"
          },
          "md": {
            "root": "h-7 px-3 text-sm",
            "dot": "h-2 w-2"
          },
          "lg": {
            "root": "h-8 px-3 text-base",
            "dot": "h-2 w-2"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "24px"
        },
        "md": {
          "minHeight": "28px"
        },
        "lg": {
          "minHeight": "32px"
        }
      },
      "states": {
        "default": {
          "root": "inline-flex items-center gap-2 rounded-full font-medium"
        },
        "hover": {
          "root": "hover:brightness-105"
        },
        "active": {
          "root": "active:brightness-95"
        },
        "focusVisible": {
          "root": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-50"
        },
        "selected": {
          "root": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Interactive badges must provide keyboard focus and pressed state semantics.",
        "notes": [
          "Status-only badges should include screen-reader text for context."
        ]
      }
    },
    "alert": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.action.success",
        "semantic.action.warning",
        "semantic.action.danger",
        "radius.lg",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "root",
        "icon",
        "title",
        "description",
        "action"
      ],
      "defaultVariants": {
        "intent": "info",
        "density": "md"
      },
      "variants": {
        "intent": {
          "info": {
            "root": "bg-semantic-bg-raised border border-semantic-border-default"
          },
          "success": {
            "root": "bg-success-100/20 border border-success-500"
          },
          "warning": {
            "root": "bg-warning-100/20 border border-warning-500"
          },
          "danger": {
            "root": "bg-danger-100/20 border border-danger-500"
          }
        },
        "density": {
          "sm": {
            "root": "p-3",
            "title": "text-sm",
            "description": "text-xs"
          },
          "md": {
            "root": "p-4",
            "title": "text-base",
            "description": "text-sm"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "56px"
        },
        "md": {
          "minHeight": "64px"
        }
      },
      "states": {
        "default": {
          "root": "rounded-lg flex items-start gap-3",
          "title": "text-semantic-text-primary font-medium",
          "description": "text-semantic-text-secondary"
        },
        "hover": {
          "root": "hover:border-semantic-border-strong"
        },
        "active": {
          "root": "active:brightness-95"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-60"
        },
        "selected": {
          "root": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use role=alert only for urgent updates; otherwise use status/live region politely.",
        "notes": [
          "Icon-only alerts must include text equivalents."
        ]
      }
    },
    "toast": {
      "requiredTokenRefs": [
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "shadow.lg",
        "radius.lg",
        "motion.duration.fast",
        "motion.easing.inOut"
      ],
      "slots": [
        "root",
        "icon",
        "title",
        "description",
        "close"
      ],
      "defaultVariants": {
        "intent": "info",
        "size": "md"
      },
      "variants": {
        "intent": {
          "info": {
            "root": "border-semantic-border-default"
          },
          "success": {
            "root": "border-success-500"
          },
          "warning": {
            "root": "border-warning-500"
          },
          "danger": {
            "root": "border-danger-500"
          }
        },
        "size": {
          "sm": {
            "root": "w-72 p-3",
            "title": "text-sm",
            "description": "text-xs"
          },
          "md": {
            "root": "w-80 p-4",
            "title": "text-base",
            "description": "text-sm"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "64px"
        },
        "md": {
          "minHeight": "72px"
        }
      },
      "states": {
        "default": {
          "root": "bg-semantic-bg-raised border rounded-lg shadow-lg transition-all duration-fast ease-in-out"
        },
        "hover": {
          "root": "hover:border-semantic-border-strong"
        },
        "active": {
          "root": "active:translate-y-px"
        },
        "focusVisible": {
          "close": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-60"
        },
        "selected": {
          "root": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Ensure close action is keyboard reachable and announcement region is polite by default.",
        "notes": [
          "Do not auto-dismiss critical error toasts before users can read them."
        ]
      }
    },
    "navigationHeader": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.bg.overlay",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "radius.full",
        "spacing.3",
        "spacing.4",
        "spacing.6"
      ],
      "slots": [
        "root",
        "brand",
        "navItem",
        "actions"
      ],
      "defaultVariants": {
        "density": "md",
        "surface": "translucent"
      },
      "variants": {
        "density": {
          "sm": {
            "root": "h-14 px-4"
          },
          "md": {
            "root": "h-16 px-6"
          }
        },
        "surface": {
          "solid": {
            "root": "bg-semantic-bg-base border-b border-semantic-border-default"
          },
          "translucent": {
            "root": "bg-semantic-bg-base/80 backdrop-blur-xl border-b border-semantic-border-muted"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "56px"
        },
        "md": {
          "minHeight": "64px"
        }
      },
      "states": {
        "default": {
          "root": "sticky top-0 z-40 flex items-center justify-between",
          "navItem": "text-semantic-text-secondary hover:text-semantic-text-primary"
        },
        "hover": {
          "navItem": "hover:bg-semantic-bg-subtle rounded-full px-3 py-2"
        },
        "active": {
          "navItem": "active:opacity-80"
        },
        "focusVisible": {
          "navItem": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "navItem": "opacity-50 pointer-events-none"
        },
        "selected": {
          "navItem": "data-[active=true]:text-semantic-text-primary data-[active=true]:bg-semantic-bg-subtle"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Preserve keyboard tab order and visible active route indication.",
        "notes": [
          "Avoid placing essential actions behind hover-only affordances."
        ]
      }
    },
    "navigationSidebar": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.text.secondary",
        "semantic.border.default",
        "radius.lg",
        "spacing.2",
        "spacing.3",
        "spacing.4"
      ],
      "slots": [
        "root",
        "section",
        "item",
        "icon",
        "label"
      ],
      "defaultVariants": {
        "width": "md"
      },
      "variants": {
        "width": {
          "sm": {
            "root": "w-56"
          },
          "md": {
            "root": "w-64"
          },
          "lg": {
            "root": "w-72"
          }
        }
      },
      "sizes": {
        "sm": {
          "minWidth": "224px"
        },
        "md": {
          "minWidth": "256px"
        },
        "lg": {
          "minWidth": "288px"
        }
      },
      "states": {
        "default": {
          "root": "h-full bg-semantic-bg-base border-r border-semantic-border-default p-3",
          "item": "flex items-center gap-3 rounded-lg px-3 py-2 text-semantic-text-secondary"
        },
        "hover": {
          "item": "hover:bg-semantic-bg-raised hover:text-semantic-text-primary"
        },
        "active": {
          "item": "active:opacity-80"
        },
        "focusVisible": {
          "item": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "item": "opacity-50 pointer-events-none"
        },
        "selected": {
          "item": "data-[active=true]:bg-semantic-bg-raised data-[active=true]:text-semantic-text-primary"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use nav landmark semantics and aria-current on active destination.",
        "notes": [
          "Collapsed sidebar mode must retain accessible labels (tooltips or sr-only text)."
        ]
      }
    },
    "modal": {
      "requiredTokenRefs": [
        "semantic.bg.scrim",
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.border.default",
        "radius.2xl",
        "shadow.lg",
        "motion.duration.base",
        "motion.easing.inOut",
        "spacing.4",
        "spacing.6"
      ],
      "slots": [
        "overlay",
        "content",
        "header",
        "body",
        "footer",
        "close"
      ],
      "defaultVariants": {
        "size": "md"
      },
      "variants": {
        "size": {
          "sm": {
            "content": "w-[min(92vw,420px)]"
          },
          "md": {
            "content": "w-[min(92vw,560px)]"
          },
          "lg": {
            "content": "w-[min(92vw,720px)]"
          }
        }
      },
      "sizes": {
        "sm": {
          "maxWidth": "420px"
        },
        "md": {
          "maxWidth": "560px"
        },
        "lg": {
          "maxWidth": "720px"
        }
      },
      "states": {
        "default": {
          "overlay": "fixed inset-0 bg-semantic-bg-scrim",
          "content": "rounded-2xl bg-semantic-bg-raised border border-semantic-border-default shadow-lg p-6"
        },
        "hover": {
          "close": "hover:bg-semantic-bg-muted"
        },
        "active": {
          "close": "active:scale-[0.98]"
        },
        "focusVisible": {
          "close": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus",
          "content": "focus:outline-none"
        },
        "disabled": {
          "close": "opacity-50 pointer-events-none"
        },
        "selected": {
          "content": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Trap focus while open and return focus to trigger on close.",
        "notes": [
          "Use aria-modal=true, role=dialog, and labelledby/description wiring.",
          "Close on Escape unless blocked by critical flow requirements."
        ]
      }
    },
    "drawer": {
      "requiredTokenRefs": [
        "semantic.bg.scrim",
        "semantic.bg.raised",
        "semantic.text.primary",
        "semantic.border.default",
        "radius.2xl",
        "shadow.lg",
        "motion.duration.base",
        "motion.easing.quick",
        "spacing.4",
        "spacing.6"
      ],
      "slots": [
        "overlay",
        "panel",
        "header",
        "body",
        "footer",
        "handle"
      ],
      "defaultVariants": {
        "side": "right",
        "size": "md"
      },
      "variants": {
        "side": {
          "right": {
            "panel": "right-0 border-l"
          },
          "left": {
            "panel": "left-0 border-r"
          },
          "bottom": {
            "panel": "bottom-0 left-0 right-0 border-t rounded-t-2xl"
          }
        },
        "size": {
          "sm": {
            "panel": "w-[min(92vw,360px)]"
          },
          "md": {
            "panel": "w-[min(92vw,440px)]"
          },
          "lg": {
            "panel": "w-[min(92vw,560px)]"
          }
        }
      },
      "sizes": {
        "sm": {
          "maxWidth": "360px"
        },
        "md": {
          "maxWidth": "440px"
        },
        "lg": {
          "maxWidth": "560px"
        }
      },
      "states": {
        "default": {
          "overlay": "fixed inset-0 bg-semantic-bg-scrim",
          "panel": "fixed top-0 h-full bg-semantic-bg-raised border-semantic-border-default shadow-lg p-6"
        },
        "hover": {
          "handle": "hover:bg-semantic-bg-muted"
        },
        "active": {
          "handle": "active:opacity-80"
        },
        "focusVisible": {
          "panel": "focus:outline-none",
          "handle": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "handle": "opacity-50 pointer-events-none"
        },
        "selected": {
          "panel": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Maintain logical reading order and trap focus when drawer is modal.",
        "notes": [
          "For bottom drawers on mobile, ensure drag handle has an accessible label.",
          "Preserve Escape and overlay-click close behavior unless blocked intentionally."
        ]
      }
    }
  }
}
```

## font-report.json
```json
{
  "fonts": [
    {
      "detected": "Basel / Basel Grotesk",
      "confidence": "likely paid",
      "freeAlternatives": [
        "Inter",
        "Plus Jakarta Sans",
        "Manrope"
      ],
      "notes": "Production app preloads Basel-Grotesk Book/Medium; Inter is the closest neutral UI fallback with similar width behavior."
    },
    {
      "detected": "Inter",
      "confidence": "free/open-source",
      "freeAlternatives": [
        "Source Sans 3",
        "Public Sans",
        "Work Sans"
      ],
      "notes": "Inter is explicitly referenced via @fontsource in the official Uniswap widgets distribution."
    },
    {
      "detected": "IBM Plex Mono",
      "confidence": "free/open-source",
      "freeAlternatives": [
        "JetBrains Mono",
        "Fira Code",
        "Source Code Pro"
      ],
      "notes": "Used as the code/monospace face in Uniswap widgets; replacements preserve technical readability."
    }
  ]
}
```

## assumptions.md
```md
- Scope is limited to Uniswap core app surfaces (swap flow, shared nav and shell primitives), not the full ecosystem.
- Theme coverage is intentionally dark-only, even though source evidence includes light-theme values.
- Strict-clone means observed production constants are preferred; inferred values exist only where a full reusable scale was not directly declared.
- Live deep-link rendering in headless mode returned `client packet length exceeds 255 buffer`, so source truth is taken from production asset bundles and public package artifacts.
- Tailwind v4 is the primary target, but `tailwind.preset.ts` remains v3-compatible through `theme.extend` mappings.
- Component blueprints prioritize deterministic token references and avoid silently introducing new token keys.
- Open question: if your implementation must exactly mirror every chain-specific branding surface, add a dedicated `network` token family beyond the current semantic core.
```

## downstream-ai-prompt.md
```md
You are given `design-system.json` and `component-blueprints.json`.

Apply these defaults even if the user does not explicitly request them:
1. Use only these two files as source of truth for tokens and component recipes.
2. Never rename token keys.
3. Never silently create new tokens.
4. If any required token is missing, continue with best-effort component code and append a separate `Missing Token Report` section.
5. Keep variants orthogonal and preserve slot-specific utility recipes.
6. Use dark-mode token values as default output; do not invent light-mode styles unless explicitly requested.

Return exactly:
1. Component code
2. Variant usage examples
3. Missing Token Report (only when required token refs are unresolved)

Missing Token Report format:
- token_path: <path>
- used_in: <component.slot or state>
- suggested_minimal_addition: <smallest additive token proposal>
```
