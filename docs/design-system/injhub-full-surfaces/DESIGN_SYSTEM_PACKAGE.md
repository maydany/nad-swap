# Design System Package

## package-meta.yaml
```yaml
schema_version: "1.0"
package_name: "injhub-full-surfaces-design-system"
generated_at: "2026-02-15T15:45:00Z"
source:
  type: "mixed"
  value: "https://injhub.com/stake + https://injhub.com/wallet + https://injhub.com/governance + https://injhub.com/community-buyback + https://injhub.com/ecosystem + https://injhub.com/_nuxt/entry.CWzN26OW.css"
tailwind_target: "v4"
match_strategy: "strict"
modes:
  - "light"
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
  overall: 0.84
  notes:
    - "Core palette, typography, spacing, radius, and motion tokens are directly observed from production CSS bundles."
    - "Runtime semantic aliases (ui-color/ui-primary family) are inferred from observed references and naming conventions."
```

## design-system.json
```json
{
  "meta": {
    "name": "injhub-full-surfaces",
    "tailwindTarget": "v4",
    "modes": [
      "light",
      "dark"
    ],
    "matchStrategy": "strict",
    "scope": [
      "/stake",
      "/wallet",
      "/governance",
      "/community-buyback",
      "/ecosystem"
    ]
  },
  "tokens": {
    "color": {
      "white": "#ffffff",
      "black": "#000000",
      "primary": {
        "50": "#ebf0ff",
        "100": "#dbe3ff",
        "200": "#becbff",
        "300": "#97a8ff",
        "400": "#5e5eff",
        "500": "#4d4cff",
        "600": "#3420e2",
        "700": "#2010d0",
        "800": "#22233c",
        "850": "#1b1f3a",
        "900": "#161a33",
        "950": "#0c0d26"
      },
      "secondary": {
        "50": "#fcfdff",
        "100": "#ebf0ff",
        "200": "#d4e0ff",
        "300": "#c2d3ff",
        "400": "#aac2ff",
        "500": "#87a7f3",
        "600": "#6c91e7",
        "700": "#4669b9",
        "800": "#314887",
        "900": "#182e4b",
        "950": "oklch(29.3% 0.066 243.157)"
      },
      "accent": {
        "50": "#fff5f0",
        "100": "#ffece0",
        "200": "#ffdbc7",
        "300": "#ffc8a8",
        "400": "#ffb58a",
        "500": "#ffa36e",
        "600": "#ff7424",
        "700": "#db5000",
        "800": "#943600",
        "900": "#471a00",
        "950": "#240d00"
      },
      "neutral": {
        "0": "#ffffff",
        "50": "oklch(98.5% 0 0)",
        "100": "oklch(97% 0 0)",
        "200": "oklch(92.2% 0 0)",
        "300": "oklch(87% 0 0)",
        "400": "oklch(70.8% 0 0)",
        "500": "oklch(55.6% 0 0)",
        "600": "oklch(43.9% 0 0)",
        "700": "oklch(37.1% 0 0)",
        "800": "oklch(26.9% 0 0)",
        "900": "oklch(20.5% 0 0)",
        "950": "oklch(14.5% 0 0)"
      },
      "success": {
        "50": "#dff7e1",
        "100": "#beeec3",
        "200": "#7dde87",
        "300": "#3ccd4b",
        "400": "#248e2f",
        "500": "#144e1a",
        "600": "#103d14",
        "700": "#0c3110",
        "800": "#08200b",
        "900": "#041005",
        "950": "#020803"
      },
      "warning": {
        "50": "#fdfff5",
        "100": "#fcffeb",
        "200": "#f8ffd1",
        "300": "#f4ffb3",
        "400": "#efff94",
        "500": "#e8ff5f",
        "600": "#c7eb00",
        "700": "#b2d100",
        "800": "#93ad00",
        "900": "#6c8000",
        "950": "#4e5c00"
      },
      "danger": {
        "100": "oklch(93.6% 0.032 17.717)",
        "200": "oklch(88.5% 0.062 18.334)",
        "400": "oklch(70.4% 0.191 22.216)",
        "500": "oklch(63.7% 0.237 25.331)"
      },
      "brand": {
        "50": "#ebf0ff",
        "100": "#dbe3ff",
        "200": "#becbff",
        "300": "#97a8ff",
        "400": "#5e5eff",
        "500": "#4d4cff",
        "600": "#3420e2",
        "700": "#2010d0",
        "800": "#22233c",
        "850": "#1b1f3a",
        "900": "#161a33",
        "950": "#0c0d26"
      },
      "ocean": {
        "50": "#e8e5ff",
        "100": "#d5d1ff",
        "200": "#a69eff",
        "300": "#7c70ff",
        "400": "#4d3dff",
        "500": "#1f0aff",
        "600": "#1100d1",
        "700": "#0d009e",
        "800": "#09006b",
        "900": "#040033",
        "950": "#020019"
      },
      "midnight": {
        "50": "#e0e9f5",
        "100": "#c1d3eb",
        "200": "#83a8d7",
        "300": "#467cc4",
        "400": "#2d558b",
        "500": "#182e4b",
        "600": "#14263e",
        "700": "#0f1c2e",
        "800": "#0a131f",
        "900": "#05090f",
        "950": "#020508"
      },
      "lemon": {
        "50": "#fdfff5",
        "100": "#fcffeb",
        "200": "#f8ffd1",
        "300": "#f4ffb3",
        "400": "#efff94",
        "500": "#e8ff5f",
        "600": "#c7eb00",
        "700": "#b2d100",
        "800": "#93ad00",
        "900": "#6c8000",
        "950": "#4e5c00"
      },
      "lime": {
        "50": "#fafffa",
        "100": "#f6fff5",
        "200": "#edffeb",
        "300": "#e4ffe0",
        "400": "#d6ffd1",
        "500": "#ceffc8",
        "550": "#b4fea9",
        "600": "#81ff70",
        "700": "#30ff14",
        "800": "#15b800",
        "900": "#0b6100",
        "950": "#063300"
      },
      "coral": {
        "50": "#fff5f0",
        "100": "#ffece0",
        "200": "#ffdbc7",
        "300": "#ffc8a8",
        "400": "#ffb58a",
        "500": "#ffa36e",
        "600": "#ff7424",
        "700": "#db5000",
        "800": "#943600",
        "900": "#471a00",
        "950": "#240d00"
      },
      "sand": {
        "50": "#fbf9f4",
        "100": "#f6f2e9",
        "200": "#efe8d7",
        "300": "#e6dcc1",
        "400": "#ddcfac",
        "500": "#d5c498",
        "600": "#c0a563",
        "700": "#9c823f",
        "800": "#69572b",
        "900": "#332a15",
        "950": "#19150a"
      },
      "cinnamon": {
        "50": "#faede1",
        "100": "#f5dac2",
        "200": "#e9b381",
        "300": "#df8f44",
        "400": "#b7691f",
        "500": "#7a4515",
        "600": "#603710",
        "700": "#4a2a0d",
        "800": "#301b08",
        "900": "#1a0f04",
        "950": "#0d0702"
      },
      "turquoise": {
        "50": "#dcf6fe",
        "100": "#b4ebfe",
        "200": "#6dd9fd",
        "300": "#22c5fc",
        "400": "#039bce",
        "500": "#026585",
        "600": "#025069",
        "700": "#013d50",
        "800": "#012a37",
        "900": "#001319",
        "950": "#000b0f"
      },
      "aubergine": {
        "50": "#f8ddef",
        "100": "#f2c0e1",
        "200": "#e47cc1",
        "300": "#d73da3",
        "400": "#a12176",
        "500": "#611447",
        "600": "#4c1038",
        "700": "#3b0c2c",
        "800": "#26081c",
        "900": "#150410",
        "950": "#080206"
      },
      "inj": {
        "sky": "#aac2ff",
        "snow": "#eeefff",
        "lime": "#ceffc8",
        "sand": "#d5c498",
        "lemon": "#e8ff5f",
        "black": "#0b182b",
        "coral": "#ffa36e",
        "ocean": "#4d3dff",
        "forest": "#144e1a",
        "cinnamon": "#7a4515",
        "midnight": "#182e4b",
        "aubergine": "#611447",
        "turquoise": "#026585"
      },
      "utility": {
        "borderGray": "#434448",
        "placeholderGray": "#727376"
      }
    },
    "typography": {
      "fontFamily": {
        "sans": [
          "ABC Whyte",
          "Inter",
          "Proxima Nova",
          "-apple-system",
          "BlinkMacSystemFont",
          "Segoe UI",
          "sans-serif"
        ],
        "ui": [
          "Inter",
          "ABC Whyte",
          "-apple-system",
          "BlinkMacSystemFont",
          "sans-serif"
        ],
        "mono": [
          "ABC Whyte Mono",
          "ui-monospace",
          "SFMono-Regular",
          "monospace"
        ]
      },
      "fontSize": {
        "xs": {
          "size": "12px",
          "lineHeight": "1.33333",
          "letterSpacing": "0"
        },
        "sm": {
          "size": "14px",
          "lineHeight": "1.42857",
          "letterSpacing": "0"
        },
        "base": {
          "size": "16px",
          "lineHeight": "1.5",
          "letterSpacing": "0"
        },
        "lg": {
          "size": "18px",
          "lineHeight": "1.55556",
          "letterSpacing": "0"
        },
        "xl": {
          "size": "20px",
          "lineHeight": "1.4",
          "letterSpacing": "-0.01em"
        },
        "2xl": {
          "size": "24px",
          "lineHeight": "1.33333",
          "letterSpacing": "-0.015em"
        },
        "3xl": {
          "size": "30px",
          "lineHeight": "1.2",
          "letterSpacing": "-0.02em"
        },
        "4xl": {
          "size": "36px",
          "lineHeight": "1.11111",
          "letterSpacing": "-0.02em"
        },
        "5xl": {
          "size": "48px",
          "lineHeight": "1",
          "letterSpacing": "-0.02em"
        },
        "7xl": {
          "size": "72px",
          "lineHeight": "1",
          "letterSpacing": "-0.03em"
        }
      },
      "fontWeight": {
        "regular": 400,
        "medium": 500,
        "semibold": 600,
        "bold": 700
      },
      "tracking": {
        "tight": "-0.025em",
        "normal": "0",
        "wide": "0.025em",
        "wider": "0.05em",
        "widest": "0.1em"
      }
    },
    "spacing": {
      "0": "0px",
      "0.5": "2px",
      "1": "4px",
      "1.5": "6px",
      "2": "8px",
      "2.5": "10px",
      "3": "12px",
      "3.5": "14px",
      "4": "16px",
      "4.5": "18px",
      "5": "20px",
      "5.5": "22px",
      "6": "24px",
      "6.5": "26px",
      "7": "28px",
      "7.5": "30px",
      "8": "32px",
      "8.5": "34px",
      "9": "36px",
      "10": "40px",
      "11": "44px",
      "12": "48px",
      "14": "56px",
      "16": "64px",
      "20": "80px",
      "24": "96px"
    },
    "radius": {
      "none": "0px",
      "xs": "2px",
      "sm": "4px",
      "md": "6px",
      "lg": "8px",
      "xl": "12px",
      "2xl": "16px",
      "full": "9999px"
    },
    "shadow": {
      "xs": "0 1px 2px 0 #0000000d",
      "sm": "0 1px 3px 0 #0000001a, 0 1px 2px -1px #0000001a",
      "md": "0 4px 6px -1px #0000001a, 0 2px 4px -2px #0000001a",
      "lg": "0 10px 15px -3px #0000001a, 0 4px 6px -4px #0000001a"
    },
    "borderWidth": {
      "DEFAULT": "1px",
      "2": "2px"
    },
    "motion": {
      "duration": {
        "fast": "100ms",
        "base": "150ms",
        "slow": "300ms",
        "slower": "500ms"
      },
      "easing": {
        "standard": "cubic-bezier(0.4, 0, 0.2, 1)",
        "in": "cubic-bezier(0.4, 0, 1, 1)",
        "out": "cubic-bezier(0, 0, 0.2, 1)",
        "entrance": "cubic-bezier(0.16, 1, 0.3, 1)",
        "exit": "cubic-bezier(0.7, 0, 0.84, 0)"
      }
    },
    "breakpoints": {
      "2xs": "375px",
      "sm": "640px",
      "md": "768px",
      "lg": "1024px",
      "xl": "1280px",
      "2xl": "1536px"
    },
    "container": {
      "maxWidth": {
        "xs": "20rem",
        "sm": "24rem",
        "md": "28rem",
        "lg": "32rem",
        "xl": "36rem",
        "2xl": "42rem",
        "3xl": "48rem",
        "5xl": "64rem",
        "7xl": "80rem",
        "app": "90rem"
      },
      "paddingInline": "1rem"
    }
  },
  "semantic": {
    "bg": {
      "base": {
        "light": "tokens.color.white",
        "dark": "tokens.color.neutral.900"
      },
      "muted": {
        "light": "tokens.color.neutral.50",
        "dark": "tokens.color.neutral.800"
      },
      "elevated": {
        "light": "tokens.color.neutral.100",
        "dark": "tokens.color.neutral.800"
      },
      "accented": {
        "light": "tokens.color.neutral.200",
        "dark": "tokens.color.neutral.700"
      },
      "inverted": {
        "light": "tokens.color.neutral.900",
        "dark": "tokens.color.white"
      }
    },
    "text": {
      "primary": {
        "light": "tokens.color.neutral.700",
        "dark": "tokens.color.neutral.200"
      },
      "muted": {
        "light": "tokens.color.neutral.500",
        "dark": "tokens.color.neutral.400"
      },
      "dimmed": {
        "light": "tokens.color.neutral.400",
        "dark": "tokens.color.neutral.500"
      },
      "highlighted": {
        "light": "tokens.color.neutral.900",
        "dark": "tokens.color.white"
      },
      "inverted": {
        "light": "tokens.color.white",
        "dark": "tokens.color.neutral.900"
      }
    },
    "border": {
      "default": {
        "light": "tokens.color.neutral.200",
        "dark": "tokens.color.neutral.800"
      },
      "muted": {
        "light": "tokens.color.neutral.200",
        "dark": "tokens.color.neutral.700"
      },
      "accented": {
        "light": "tokens.color.neutral.300",
        "dark": "tokens.color.neutral.700"
      },
      "inverted": {
        "light": "tokens.color.neutral.900",
        "dark": "tokens.color.white"
      },
      "focus": "tokens.color.primary.500"
    },
    "action": {
      "primary": "tokens.color.primary.500",
      "primaryHover": "tokens.color.primary.600",
      "secondary": "tokens.color.secondary.500",
      "secondaryHover": "tokens.color.secondary.600",
      "success": "tokens.color.success.500",
      "warning": "tokens.color.warning.500",
      "danger": "tokens.color.danger.500",
      "dangerHover": "tokens.color.danger.400",
      "info": "tokens.color.secondary.500"
    },
    "status": {
      "success": {
        "fg": "tokens.color.success.500",
        "bgSoft": "tokens.color.success.100"
      },
      "warning": {
        "fg": "tokens.color.warning.700",
        "bgSoft": "tokens.color.warning.100"
      },
      "danger": {
        "fg": "tokens.color.danger.500",
        "bgSoft": "tokens.color.danger.100"
      },
      "info": {
        "fg": "tokens.color.secondary.700",
        "bgSoft": "tokens.color.secondary.100"
      }
    },
    "aliases": {
      "ui-color-neutral-50": "tokens.color.neutral.50",
      "ui-color-neutral-100": "tokens.color.neutral.100",
      "ui-color-neutral-200": "tokens.color.neutral.200",
      "ui-color-neutral-300": "tokens.color.neutral.300",
      "ui-color-neutral-400": "tokens.color.neutral.400",
      "ui-color-neutral-500": "tokens.color.neutral.500",
      "ui-color-neutral-600": "tokens.color.neutral.600",
      "ui-color-neutral-700": "tokens.color.neutral.700",
      "ui-color-neutral-800": "tokens.color.neutral.800",
      "ui-color-neutral-900": "tokens.color.neutral.900",
      "ui-color-primary-200": "tokens.color.primary.200",
      "ui-color-primary-300": "tokens.color.primary.300",
      "ui-color-primary-400": "tokens.color.primary.400",
      "ui-color-primary-500": "tokens.color.primary.500",
      "ui-color-primary-600": "tokens.color.primary.600",
      "ui-color-primary-800": "tokens.color.primary.800",
      "ui-primary": "tokens.color.primary.500",
      "ui-secondary": "tokens.color.secondary.500",
      "ui-success": "tokens.color.success.500",
      "ui-warning": "tokens.color.warning.500",
      "ui-error": "tokens.color.danger.500",
      "ui-info": "tokens.color.secondary.500"
    }
  },
  "modes": {
    "default": "dark",
    "light": {
      "ui-text-dimmed": "tokens.color.neutral.400",
      "ui-text-muted": "tokens.color.neutral.500",
      "ui-text-toned": "tokens.color.neutral.600",
      "ui-text": "tokens.color.neutral.700",
      "ui-text-highlighted": "tokens.color.neutral.900",
      "ui-text-inverted": "tokens.color.white",
      "ui-bg": "tokens.color.white",
      "ui-bg-muted": "tokens.color.neutral.50",
      "ui-bg-elevated": "tokens.color.neutral.100",
      "ui-bg-accented": "tokens.color.neutral.200",
      "ui-bg-inverted": "tokens.color.neutral.900",
      "ui-border": "tokens.color.neutral.200",
      "ui-border-muted": "tokens.color.neutral.200",
      "ui-border-accented": "tokens.color.neutral.300",
      "ui-border-inverted": "tokens.color.neutral.900"
    },
    "dark": {
      "ui-text-dimmed": "tokens.color.neutral.500",
      "ui-text-muted": "tokens.color.neutral.400",
      "ui-text-toned": "tokens.color.neutral.300",
      "ui-text": "tokens.color.neutral.200",
      "ui-text-highlighted": "tokens.color.white",
      "ui-text-inverted": "tokens.color.neutral.900",
      "ui-bg": "tokens.color.neutral.900",
      "ui-bg-muted": "tokens.color.neutral.800",
      "ui-bg-elevated": "tokens.color.neutral.800",
      "ui-bg-accented": "tokens.color.neutral.700",
      "ui-bg-inverted": "tokens.color.white",
      "ui-border": "tokens.color.neutral.800",
      "ui-border-muted": "tokens.color.neutral.700",
      "ui-border-accented": "tokens.color.neutral.700",
      "ui-border-inverted": "tokens.color.white"
    }
  },
  "evidence": {
    "observed": [
      "Live stake route shell preloads ABCWhyte-Regular.woff2 and toggles color mode classes using dark as fallback.",
      "Production CSS defines @font-face for ABC Whyte, ABC Whyte Mono, Inter, and Proxima Nova.",
      "Production CSS defines brand scale --color-brand-50..950 and injective palette aliases (inj-sky, inj-black, inj-coral, etc.).",
      "Production CSS defines expanded palettes: midnight, ocean, lemon, lime, coral, sand, cinnamon, turquoise, aubergine.",
      "Production CSS defines spacing base --spacing: .25rem and utility usage confirms half-step multipliers (e.g., 3.5, 4.5, 8.5).",
      "Production CSS defines typography scale variables for xs/sm/base/lg/xl/2xl/3xl/4xl/5xl/7xl with line-height pairs.",
      "Production CSS defines radius variables xs..2xl and shadow utility values for xs/sm/md/lg.",
      "Production CSS defines motion tokens: default transition duration 0.15s and cubic-bezier(0.4,0,0.2,1), plus ease-in and ease-out.",
      "Rendered /stake content shows staking form, rewards cards, and validator data-table patterns.",
      "Rendered /governance content shows proposal list, KPI stats, and tab-like filter controls.",
      "Rendered /community-buyback content shows gradient card treatment, buyback history table, and stat blocks.",
      "Rendered /wallet and /ecosystem content confirm empty-state card patterns and media-heavy card grid patterns."
    ],
    "inferred": [
      {
        "item": "ui-color-neutral-50..900 map to neutral scale from observed old-neutral values",
        "confidence": 0.79,
        "reason": "ui-color-neutral tokens are referenced extensively but not explicitly declared in fetched CSS; references align with neutral role usage in light/dark mode mappings."
      },
      {
        "item": "ui-color-primary-200/300/400/500/600/800 map to brand scale tokens",
        "confidence": 0.84,
        "reason": "primary utilities co-occur with brand-* classes and matching tonal behavior across states indicates shared source scale."
      },
      {
        "item": "ui-primary resolves to ui-color-primary-500",
        "confidence": 0.9,
        "reason": "semantic action utilities consistently use ui-primary for primary-filled surfaces and hover variants tied to primary-600."
      },
      {
        "item": "ui-secondary resolves to secondary sky scale (500 baseline)",
        "confidence": 0.58,
        "reason": "secondary semantic tokens are referenced without direct declaration; sky palette is the closest observed non-primary informational accent family."
      },
      {
        "item": "ui-success/ui-warning/ui-error/ui-info map to success.500/warning.500/danger.500/secondary.500",
        "confidence": 0.66,
        "reason": "status naming conventions and observed utility usage patterns match standard semantic assignment, but explicit source declarations were not present in fetched CSS."
      },
      {
        "item": "mode default remains dark",
        "confidence": 0.95,
        "reason": "inline boot script sets color mode preference fallback to dark when local storage key is missing."
      }
    ]
  }
}
```

## tailwind.preset.ts
```ts
import type { Config } from "tailwindcss";

const preset: Partial<Config> = {
  darkMode: ["class"],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "var(--ds-color-primary-50)",
          100: "var(--ds-color-primary-100)",
          200: "var(--ds-color-primary-200)",
          300: "var(--ds-color-primary-300)",
          400: "var(--ds-color-primary-400)",
          500: "var(--ds-color-primary-500)",
          600: "var(--ds-color-primary-600)",
          700: "var(--ds-color-primary-700)",
          800: "var(--ds-color-primary-800)",
          850: "var(--ds-color-primary-850)",
          900: "var(--ds-color-primary-900)",
          950: "var(--ds-color-primary-950)"
        },
        secondary: {
          50: "var(--ds-color-secondary-50)",
          100: "var(--ds-color-secondary-100)",
          200: "var(--ds-color-secondary-200)",
          300: "var(--ds-color-secondary-300)",
          400: "var(--ds-color-secondary-400)",
          500: "var(--ds-color-secondary-500)",
          600: "var(--ds-color-secondary-600)",
          700: "var(--ds-color-secondary-700)",
          800: "var(--ds-color-secondary-800)",
          900: "var(--ds-color-secondary-900)",
          950: "var(--ds-color-secondary-950)"
        },
        accent: {
          50: "var(--ds-color-accent-50)",
          100: "var(--ds-color-accent-100)",
          200: "var(--ds-color-accent-200)",
          300: "var(--ds-color-accent-300)",
          400: "var(--ds-color-accent-400)",
          500: "var(--ds-color-accent-500)",
          600: "var(--ds-color-accent-600)",
          700: "var(--ds-color-accent-700)",
          800: "var(--ds-color-accent-800)",
          900: "var(--ds-color-accent-900)",
          950: "var(--ds-color-accent-950)"
        },
        neutral: {
          0: "var(--ds-color-neutral-0)",
          50: "var(--ds-color-neutral-50)",
          100: "var(--ds-color-neutral-100)",
          200: "var(--ds-color-neutral-200)",
          300: "var(--ds-color-neutral-300)",
          400: "var(--ds-color-neutral-400)",
          500: "var(--ds-color-neutral-500)",
          600: "var(--ds-color-neutral-600)",
          700: "var(--ds-color-neutral-700)",
          800: "var(--ds-color-neutral-800)",
          900: "var(--ds-color-neutral-900)",
          950: "var(--ds-color-neutral-950)"
        },
        success: {
          100: "var(--ds-color-success-100)",
          500: "var(--ds-color-success-500)"
        },
        warning: {
          100: "var(--ds-color-warning-100)",
          500: "var(--ds-color-warning-500)",
          700: "var(--ds-color-warning-700)"
        },
        danger: {
          100: "var(--ds-color-danger-100)",
          400: "var(--ds-color-danger-400)",
          500: "var(--ds-color-danger-500)"
        },
        semantic: {
          bg: {
            base: "var(--ds-semantic-bg-base)",
            muted: "var(--ds-semantic-bg-muted)",
            elevated: "var(--ds-semantic-bg-elevated)",
            accented: "var(--ds-semantic-bg-accented)",
            inverted: "var(--ds-semantic-bg-inverted)"
          },
          text: {
            primary: "var(--ds-semantic-text-primary)",
            muted: "var(--ds-semantic-text-muted)",
            dimmed: "var(--ds-semantic-text-dimmed)",
            highlighted: "var(--ds-semantic-text-highlighted)",
            inverted: "var(--ds-semantic-text-inverted)"
          },
          border: {
            DEFAULT: "var(--ds-semantic-border-default)",
            muted: "var(--ds-semantic-border-muted)",
            accented: "var(--ds-semantic-border-accented)",
            inverted: "var(--ds-semantic-border-inverted)",
            focus: "var(--ds-semantic-border-focus)"
          },
          action: {
            primary: "var(--ds-semantic-action-primary)",
            primaryHover: "var(--ds-semantic-action-primary-hover)",
            secondary: "var(--ds-semantic-action-secondary)",
            secondaryHover: "var(--ds-semantic-action-secondary-hover)",
            success: "var(--ds-semantic-action-success)",
            warning: "var(--ds-semantic-action-warning)",
            danger: "var(--ds-semantic-action-danger)",
            dangerHover: "var(--ds-semantic-action-danger-hover)",
            info: "var(--ds-semantic-action-info)"
          }
        }
      },
      fontFamily: {
        sans: ["var(--ds-font-sans)"],
        ui: ["var(--ds-font-ui)"],
        mono: ["var(--ds-font-mono)"]
      },
      fontSize: {
        xs: ["var(--ds-text-xs)", { lineHeight: "var(--ds-text-xs-line-height)", letterSpacing: "var(--ds-tracking-normal)" }],
        sm: ["var(--ds-text-sm)", { lineHeight: "var(--ds-text-sm-line-height)", letterSpacing: "var(--ds-tracking-normal)" }],
        base: ["var(--ds-text-base)", { lineHeight: "var(--ds-text-base-line-height)", letterSpacing: "var(--ds-tracking-normal)" }],
        lg: ["var(--ds-text-lg)", { lineHeight: "var(--ds-text-lg-line-height)", letterSpacing: "var(--ds-tracking-normal)" }],
        xl: ["var(--ds-text-xl)", { lineHeight: "var(--ds-text-xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }],
        "2xl": ["var(--ds-text-2xl)", { lineHeight: "var(--ds-text-2xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }],
        "3xl": ["var(--ds-text-3xl)", { lineHeight: "var(--ds-text-3xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }],
        "4xl": ["var(--ds-text-4xl)", { lineHeight: "var(--ds-text-4xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }],
        "5xl": ["var(--ds-text-5xl)", { lineHeight: "var(--ds-text-5xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }],
        "7xl": ["var(--ds-text-7xl)", { lineHeight: "var(--ds-text-7xl-line-height)", letterSpacing: "var(--ds-tracking-tight)" }]
      },
      spacing: {
        "0": "var(--ds-space-0)",
        "0.5": "var(--ds-space-0_5)",
        "1": "var(--ds-space-1)",
        "1.5": "var(--ds-space-1_5)",
        "2": "var(--ds-space-2)",
        "2.5": "var(--ds-space-2_5)",
        "3": "var(--ds-space-3)",
        "3.5": "var(--ds-space-3_5)",
        "4": "var(--ds-space-4)",
        "4.5": "var(--ds-space-4_5)",
        "5": "var(--ds-space-5)",
        "5.5": "var(--ds-space-5_5)",
        "6": "var(--ds-space-6)",
        "6.5": "var(--ds-space-6_5)",
        "7": "var(--ds-space-7)",
        "7.5": "var(--ds-space-7_5)",
        "8": "var(--ds-space-8)",
        "8.5": "var(--ds-space-8_5)",
        "9": "var(--ds-space-9)",
        "10": "var(--ds-space-10)",
        "11": "var(--ds-space-11)",
        "12": "var(--ds-space-12)",
        "14": "var(--ds-space-14)",
        "16": "var(--ds-space-16)",
        "20": "var(--ds-space-20)",
        "24": "var(--ds-space-24)"
      },
      borderRadius: {
        none: "var(--ds-radius-none)",
        xs: "var(--ds-radius-xs)",
        sm: "var(--ds-radius-sm)",
        md: "var(--ds-radius-md)",
        lg: "var(--ds-radius-lg)",
        xl: "var(--ds-radius-xl)",
        "2xl": "var(--ds-radius-2xl)",
        full: "var(--ds-radius-full)"
      },
      boxShadow: {
        xs: "var(--ds-shadow-xs)",
        sm: "var(--ds-shadow-sm)",
        md: "var(--ds-shadow-md)",
        lg: "var(--ds-shadow-lg)"
      },
      borderWidth: {
        DEFAULT: "var(--ds-border-width-default)",
        2: "var(--ds-border-width-2)"
      },
      transitionDuration: {
        fast: "var(--ds-duration-fast)",
        base: "var(--ds-duration-base)",
        slow: "var(--ds-duration-slow)",
        slower: "var(--ds-duration-slower)"
      },
      transitionTimingFunction: {
        standard: "var(--ds-ease-standard)",
        in: "var(--ds-ease-in)",
        out: "var(--ds-ease-out)",
        entrance: "var(--ds-ease-entrance)",
        exit: "var(--ds-ease-exit)"
      },
      screens: {
        "2xs": "var(--ds-breakpoint-2xs)",
        sm: "var(--ds-breakpoint-sm)",
        md: "var(--ds-breakpoint-md)",
        lg: "var(--ds-breakpoint-lg)",
        xl: "var(--ds-breakpoint-xl)",
        "2xl": "var(--ds-breakpoint-2xl)"
      },
      maxWidth: {
        xs: "var(--ds-container-xs)",
        sm: "var(--ds-container-sm)",
        md: "var(--ds-container-md)",
        lg: "var(--ds-container-lg)",
        xl: "var(--ds-container-xl)",
        "2xl": "var(--ds-container-2xl)",
        "3xl": "var(--ds-container-3xl)",
        "5xl": "var(--ds-container-5xl)",
        "7xl": "var(--ds-container-7xl)",
        app: "var(--ds-container-app)"
      }
    }
  }
};

export default preset;
```

## tokens.css
```css
:root {
  --ds-font-sans: "ABC Whyte", Inter, "Proxima Nova", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --ds-font-ui: Inter, "ABC Whyte", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --ds-font-mono: "ABC Whyte Mono", ui-monospace, SFMono-Regular, monospace;

  --ds-color-primary-50: #ebf0ff;
  --ds-color-primary-100: #dbe3ff;
  --ds-color-primary-200: #becbff;
  --ds-color-primary-300: #97a8ff;
  --ds-color-primary-400: #5e5eff;
  --ds-color-primary-500: #4d4cff;
  --ds-color-primary-600: #3420e2;
  --ds-color-primary-700: #2010d0;
  --ds-color-primary-800: #22233c;
  --ds-color-primary-850: #1b1f3a;
  --ds-color-primary-900: #161a33;
  --ds-color-primary-950: #0c0d26;

  --ds-color-secondary-50: #fcfdff;
  --ds-color-secondary-100: #ebf0ff;
  --ds-color-secondary-200: #d4e0ff;
  --ds-color-secondary-300: #c2d3ff;
  --ds-color-secondary-400: #aac2ff;
  --ds-color-secondary-500: #87a7f3;
  --ds-color-secondary-600: #6c91e7;
  --ds-color-secondary-700: #4669b9;
  --ds-color-secondary-800: #314887;
  --ds-color-secondary-900: #182e4b;
  --ds-color-secondary-950: oklch(29.3% 0.066 243.157);

  --ds-color-accent-50: #fff5f0;
  --ds-color-accent-100: #ffece0;
  --ds-color-accent-200: #ffdbc7;
  --ds-color-accent-300: #ffc8a8;
  --ds-color-accent-400: #ffb58a;
  --ds-color-accent-500: #ffa36e;
  --ds-color-accent-600: #ff7424;
  --ds-color-accent-700: #db5000;
  --ds-color-accent-800: #943600;
  --ds-color-accent-900: #471a00;
  --ds-color-accent-950: #240d00;

  --ds-color-neutral-0: #ffffff;
  --ds-color-neutral-50: oklch(98.5% 0 0);
  --ds-color-neutral-100: oklch(97% 0 0);
  --ds-color-neutral-200: oklch(92.2% 0 0);
  --ds-color-neutral-300: oklch(87% 0 0);
  --ds-color-neutral-400: oklch(70.8% 0 0);
  --ds-color-neutral-500: oklch(55.6% 0 0);
  --ds-color-neutral-600: oklch(43.9% 0 0);
  --ds-color-neutral-700: oklch(37.1% 0 0);
  --ds-color-neutral-800: oklch(26.9% 0 0);
  --ds-color-neutral-900: oklch(20.5% 0 0);
  --ds-color-neutral-950: oklch(14.5% 0 0);

  --ds-color-success-100: #beeec3;
  --ds-color-success-500: #144e1a;
  --ds-color-warning-100: #fcffeb;
  --ds-color-warning-500: #e8ff5f;
  --ds-color-warning-700: #b2d100;
  --ds-color-danger-100: oklch(93.6% 0.032 17.717);
  --ds-color-danger-400: oklch(70.4% 0.191 22.216);
  --ds-color-danger-500: oklch(63.7% 0.237 25.331);

  --ds-text-xs: 0.75rem;
  --ds-text-xs-line-height: 1.33333;
  --ds-text-sm: 0.875rem;
  --ds-text-sm-line-height: 1.42857;
  --ds-text-base: 1rem;
  --ds-text-base-line-height: 1.5;
  --ds-text-lg: 1.125rem;
  --ds-text-lg-line-height: 1.55556;
  --ds-text-xl: 1.25rem;
  --ds-text-xl-line-height: 1.4;
  --ds-text-2xl: 1.5rem;
  --ds-text-2xl-line-height: 1.33333;
  --ds-text-3xl: 1.875rem;
  --ds-text-3xl-line-height: 1.2;
  --ds-text-4xl: 2.25rem;
  --ds-text-4xl-line-height: 1.11111;
  --ds-text-5xl: 3rem;
  --ds-text-5xl-line-height: 1;
  --ds-text-7xl: 4.5rem;
  --ds-text-7xl-line-height: 1;

  --ds-tracking-tight: -0.025em;
  --ds-tracking-normal: 0;
  --ds-tracking-wide: 0.025em;
  --ds-tracking-wider: 0.05em;
  --ds-tracking-widest: 0.1em;

  --ds-space-0: 0px;
  --ds-space-0_5: 2px;
  --ds-space-1: 4px;
  --ds-space-1_5: 6px;
  --ds-space-2: 8px;
  --ds-space-2_5: 10px;
  --ds-space-3: 12px;
  --ds-space-3_5: 14px;
  --ds-space-4: 16px;
  --ds-space-4_5: 18px;
  --ds-space-5: 20px;
  --ds-space-5_5: 22px;
  --ds-space-6: 24px;
  --ds-space-6_5: 26px;
  --ds-space-7: 28px;
  --ds-space-7_5: 30px;
  --ds-space-8: 32px;
  --ds-space-8_5: 34px;
  --ds-space-9: 36px;
  --ds-space-10: 40px;
  --ds-space-11: 44px;
  --ds-space-12: 48px;
  --ds-space-14: 56px;
  --ds-space-16: 64px;
  --ds-space-20: 80px;
  --ds-space-24: 96px;

  --ds-radius-none: 0px;
  --ds-radius-xs: 2px;
  --ds-radius-sm: 4px;
  --ds-radius-md: 6px;
  --ds-radius-lg: 8px;
  --ds-radius-xl: 12px;
  --ds-radius-2xl: 16px;
  --ds-radius-full: 9999px;

  --ds-shadow-xs: 0 1px 2px 0 #0000000d;
  --ds-shadow-sm: 0 1px 3px 0 #0000001a, 0 1px 2px -1px #0000001a;
  --ds-shadow-md: 0 4px 6px -1px #0000001a, 0 2px 4px -2px #0000001a;
  --ds-shadow-lg: 0 10px 15px -3px #0000001a, 0 4px 6px -4px #0000001a;

  --ds-border-width-default: 1px;
  --ds-border-width-2: 2px;

  --ds-duration-fast: 100ms;
  --ds-duration-base: 150ms;
  --ds-duration-slow: 300ms;
  --ds-duration-slower: 500ms;

  --ds-ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ds-ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ds-ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ds-ease-entrance: cubic-bezier(0.16, 1, 0.3, 1);
  --ds-ease-exit: cubic-bezier(0.7, 0, 0.84, 0);

  --ds-breakpoint-2xs: 375px;
  --ds-breakpoint-sm: 640px;
  --ds-breakpoint-md: 768px;
  --ds-breakpoint-lg: 1024px;
  --ds-breakpoint-xl: 1280px;
  --ds-breakpoint-2xl: 1536px;

  --ds-container-xs: 20rem;
  --ds-container-sm: 24rem;
  --ds-container-md: 28rem;
  --ds-container-lg: 32rem;
  --ds-container-xl: 36rem;
  --ds-container-2xl: 42rem;
  --ds-container-3xl: 48rem;
  --ds-container-5xl: 64rem;
  --ds-container-7xl: 80rem;
  --ds-container-app: 90rem;
}

:root,
.dark {
  --ds-mode: dark;

  --ds-ui-color-neutral-50: var(--ds-color-neutral-50);
  --ds-ui-color-neutral-100: var(--ds-color-neutral-100);
  --ds-ui-color-neutral-200: var(--ds-color-neutral-200);
  --ds-ui-color-neutral-300: var(--ds-color-neutral-300);
  --ds-ui-color-neutral-400: var(--ds-color-neutral-400);
  --ds-ui-color-neutral-500: var(--ds-color-neutral-500);
  --ds-ui-color-neutral-600: var(--ds-color-neutral-600);
  --ds-ui-color-neutral-700: var(--ds-color-neutral-700);
  --ds-ui-color-neutral-800: var(--ds-color-neutral-800);
  --ds-ui-color-neutral-900: var(--ds-color-neutral-900);

  --ds-ui-color-primary-200: var(--ds-color-primary-200);
  --ds-ui-color-primary-300: var(--ds-color-primary-300);
  --ds-ui-color-primary-400: var(--ds-color-primary-400);
  --ds-ui-color-primary-500: var(--ds-color-primary-500);
  --ds-ui-color-primary-600: var(--ds-color-primary-600);
  --ds-ui-color-primary-800: var(--ds-color-primary-800);

  --ds-ui-primary: var(--ds-ui-color-primary-500);
  --ds-ui-secondary: var(--ds-color-secondary-500);
  --ds-ui-success: var(--ds-color-success-500);
  --ds-ui-warning: var(--ds-color-warning-500);
  --ds-ui-error: var(--ds-color-danger-500);
  --ds-ui-info: var(--ds-color-secondary-500);

  --ds-ui-text-dimmed: var(--ds-ui-color-neutral-500);
  --ds-ui-text-muted: var(--ds-ui-color-neutral-400);
  --ds-ui-text-toned: var(--ds-ui-color-neutral-300);
  --ds-ui-text: var(--ds-ui-color-neutral-200);
  --ds-ui-text-highlighted: #ffffff;
  --ds-ui-text-inverted: var(--ds-ui-color-neutral-900);

  --ds-ui-bg: var(--ds-ui-color-neutral-900);
  --ds-ui-bg-muted: var(--ds-ui-color-neutral-800);
  --ds-ui-bg-elevated: var(--ds-ui-color-neutral-800);
  --ds-ui-bg-accented: var(--ds-ui-color-neutral-700);
  --ds-ui-bg-inverted: #ffffff;

  --ds-ui-border: var(--ds-ui-color-neutral-800);
  --ds-ui-border-muted: var(--ds-ui-color-neutral-700);
  --ds-ui-border-accented: var(--ds-ui-color-neutral-700);
  --ds-ui-border-inverted: #ffffff;

  --ds-semantic-bg-base: var(--ds-ui-bg);
  --ds-semantic-bg-muted: var(--ds-ui-bg-muted);
  --ds-semantic-bg-elevated: var(--ds-ui-bg-elevated);
  --ds-semantic-bg-accented: var(--ds-ui-bg-accented);
  --ds-semantic-bg-inverted: var(--ds-ui-bg-inverted);

  --ds-semantic-text-primary: var(--ds-ui-text);
  --ds-semantic-text-muted: var(--ds-ui-text-muted);
  --ds-semantic-text-dimmed: var(--ds-ui-text-dimmed);
  --ds-semantic-text-highlighted: var(--ds-ui-text-highlighted);
  --ds-semantic-text-inverted: var(--ds-ui-text-inverted);

  --ds-semantic-border-default: var(--ds-ui-border);
  --ds-semantic-border-muted: var(--ds-ui-border-muted);
  --ds-semantic-border-accented: var(--ds-ui-border-accented);
  --ds-semantic-border-inverted: var(--ds-ui-border-inverted);
  --ds-semantic-border-focus: var(--ds-ui-primary);

  --ds-semantic-action-primary: var(--ds-ui-primary);
  --ds-semantic-action-primary-hover: var(--ds-ui-color-primary-600);
  --ds-semantic-action-secondary: var(--ds-ui-secondary);
  --ds-semantic-action-secondary-hover: var(--ds-color-secondary-600);
  --ds-semantic-action-success: var(--ds-ui-success);
  --ds-semantic-action-warning: var(--ds-ui-warning);
  --ds-semantic-action-danger: var(--ds-ui-error);
  --ds-semantic-action-danger-hover: var(--ds-color-danger-400);
  --ds-semantic-action-info: var(--ds-ui-info);
}

.light {
  --ds-mode: light;

  --ds-ui-color-neutral-50: var(--ds-color-neutral-50);
  --ds-ui-color-neutral-100: var(--ds-color-neutral-100);
  --ds-ui-color-neutral-200: var(--ds-color-neutral-200);
  --ds-ui-color-neutral-300: var(--ds-color-neutral-300);
  --ds-ui-color-neutral-400: var(--ds-color-neutral-400);
  --ds-ui-color-neutral-500: var(--ds-color-neutral-500);
  --ds-ui-color-neutral-600: var(--ds-color-neutral-600);
  --ds-ui-color-neutral-700: var(--ds-color-neutral-700);
  --ds-ui-color-neutral-800: var(--ds-color-neutral-800);
  --ds-ui-color-neutral-900: var(--ds-color-neutral-900);

  --ds-ui-color-primary-200: var(--ds-color-primary-200);
  --ds-ui-color-primary-300: var(--ds-color-primary-300);
  --ds-ui-color-primary-400: var(--ds-color-primary-400);
  --ds-ui-color-primary-500: var(--ds-color-primary-500);
  --ds-ui-color-primary-600: var(--ds-color-primary-600);
  --ds-ui-color-primary-800: var(--ds-color-primary-800);

  --ds-ui-primary: var(--ds-ui-color-primary-500);
  --ds-ui-secondary: var(--ds-color-secondary-500);
  --ds-ui-success: var(--ds-color-success-500);
  --ds-ui-warning: var(--ds-color-warning-500);
  --ds-ui-error: var(--ds-color-danger-500);
  --ds-ui-info: var(--ds-color-secondary-500);

  --ds-ui-text-dimmed: var(--ds-ui-color-neutral-400);
  --ds-ui-text-muted: var(--ds-ui-color-neutral-500);
  --ds-ui-text-toned: var(--ds-ui-color-neutral-600);
  --ds-ui-text: var(--ds-ui-color-neutral-700);
  --ds-ui-text-highlighted: var(--ds-ui-color-neutral-900);
  --ds-ui-text-inverted: #ffffff;

  --ds-ui-bg: #ffffff;
  --ds-ui-bg-muted: var(--ds-ui-color-neutral-50);
  --ds-ui-bg-elevated: var(--ds-ui-color-neutral-100);
  --ds-ui-bg-accented: var(--ds-ui-color-neutral-200);
  --ds-ui-bg-inverted: var(--ds-ui-color-neutral-900);

  --ds-ui-border: var(--ds-ui-color-neutral-200);
  --ds-ui-border-muted: var(--ds-ui-color-neutral-200);
  --ds-ui-border-accented: var(--ds-ui-color-neutral-300);
  --ds-ui-border-inverted: var(--ds-ui-color-neutral-900);

  --ds-semantic-bg-base: var(--ds-ui-bg);
  --ds-semantic-bg-muted: var(--ds-ui-bg-muted);
  --ds-semantic-bg-elevated: var(--ds-ui-bg-elevated);
  --ds-semantic-bg-accented: var(--ds-ui-bg-accented);
  --ds-semantic-bg-inverted: var(--ds-ui-bg-inverted);

  --ds-semantic-text-primary: var(--ds-ui-text);
  --ds-semantic-text-muted: var(--ds-ui-text-muted);
  --ds-semantic-text-dimmed: var(--ds-ui-text-dimmed);
  --ds-semantic-text-highlighted: var(--ds-ui-text-highlighted);
  --ds-semantic-text-inverted: var(--ds-ui-text-inverted);

  --ds-semantic-border-default: var(--ds-ui-border);
  --ds-semantic-border-muted: var(--ds-ui-border-muted);
  --ds-semantic-border-accented: var(--ds-ui-border-accented);
  --ds-semantic-border-inverted: var(--ds-ui-border-inverted);
  --ds-semantic-border-focus: var(--ds-ui-primary);

  --ds-semantic-action-primary: var(--ds-ui-primary);
  --ds-semantic-action-primary-hover: var(--ds-ui-color-primary-600);
  --ds-semantic-action-secondary: var(--ds-ui-secondary);
  --ds-semantic-action-secondary-hover: var(--ds-color-secondary-600);
  --ds-semantic-action-success: var(--ds-ui-success);
  --ds-semantic-action-warning: var(--ds-ui-warning);
  --ds-semantic-action-danger: var(--ds-ui-error);
  --ds-semantic-action-danger-hover: var(--ds-color-danger-400);
  --ds-semantic-action-info: var(--ds-ui-info);
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
        "semantic.action.success",
        "semantic.action.warning",
        "semantic.action.danger",
        "semantic.action.dangerHover",
        "semantic.border.focus",
        "tokens.radius.md",
        "tokens.spacing.2",
        "tokens.spacing.4"
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
            "root": "text-semantic-text-inverted"
          },
          "secondary": {
            "root": "text-semantic-text-inverted"
          },
          "success": {
            "root": "text-semantic-text-inverted"
          },
          "warning": {
            "root": "text-semantic-text-highlighted"
          },
          "danger": {
            "root": "text-semantic-text-inverted"
          }
        },
        "appearance": {
          "solid": {
            "root": "border border-transparent"
          },
          "outline": {
            "root": "bg-transparent border border-semantic-border-default text-semantic-text-primary"
          },
          "ghost": {
            "root": "bg-transparent border border-transparent text-semantic-text-primary"
          }
        },
        "size": {
          "sm": {
            "root": "h-9 px-3 gap-2 rounded-md text-sm font-medium",
            "icon": "h-4 w-4"
          },
          "md": {
            "root": "h-10 px-4 gap-2 rounded-lg text-base font-medium",
            "icon": "h-4 w-4"
          },
          "lg": {
            "root": "h-12 px-5 gap-3 rounded-xl text-lg font-semibold",
            "icon": "h-5 w-5"
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
          "root": "inline-flex items-center justify-center transition-colors duration-base ease-standard"
        },
        "hover": {
          "root": "hover:brightness-110"
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
        }
      ],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use visible 2px focus ring with >=3:1 contrast against surrounding surface.",
        "notes": [
          "Do not encode destructive intent by color alone.",
          "Preserve disabled semantics with native disabled attribute when possible."
        ]
      }
    },
    "input": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.text.primary",
        "semantic.text.muted",
        "semantic.border.default",
        "semantic.border.focus",
        "tokens.radius.xl",
        "tokens.spacing.3",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "field",
        "leading",
        "trailing",
        "helper"
      ],
      "defaultVariants": {
        "size": "md",
        "tone": "default"
      },
      "variants": {
        "size": {
          "sm": {
            "root": "h-10 px-3 rounded-lg",
            "field": "text-sm"
          },
          "md": {
            "root": "h-12 px-4 rounded-xl",
            "field": "text-base"
          },
          "lg": {
            "root": "h-14 px-4 rounded-2xl",
            "field": "text-lg"
          }
        },
        "tone": {
          "default": {
            "root": "bg-semantic-bg-elevated border border-semantic-border-default",
            "helper": "text-semantic-text-muted"
          },
          "error": {
            "root": "bg-semantic-bg-elevated border border-danger-500",
            "helper": "text-danger-500"
          },
          "success": {
            "root": "bg-semantic-bg-elevated border border-success-500",
            "helper": "text-success-500"
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
          "root": "flex items-center gap-2 transition-colors duration-base ease-standard",
          "field": "w-full bg-transparent text-semantic-text-primary placeholder:text-semantic-text-muted focus:outline-none"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:border-semantic-border-accented"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus focus-within:ring-offset-2 focus-within:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "root": "opacity-50 pointer-events-none",
          "field": "cursor-not-allowed"
        },
        "selected": {
          "root": "data-[selected=true]:border-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Use focus-within ring for grouped controls and preserve native input focus visibility.",
        "notes": [
          "Pair with persistent visible label.",
          "Set aria-invalid=true on tone=error controls."
        ]
      }
    },
    "textarea": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.text.primary",
        "semantic.text.muted",
        "semantic.border.default",
        "semantic.border.focus",
        "tokens.radius.xl",
        "tokens.spacing.3",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "field",
        "helper"
      ],
      "defaultVariants": {
        "size": "md",
        "tone": "default"
      },
      "variants": {
        "size": {
          "sm": {
            "root": "p-3 rounded-lg",
            "field": "min-h-24 text-sm"
          },
          "md": {
            "root": "p-4 rounded-xl",
            "field": "min-h-32 text-base"
          },
          "lg": {
            "root": "p-4 rounded-2xl",
            "field": "min-h-40 text-lg"
          }
        },
        "tone": {
          "default": {
            "root": "bg-semantic-bg-elevated border border-semantic-border-default"
          },
          "error": {
            "root": "bg-semantic-bg-elevated border border-danger-500"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "96px"
        },
        "md": {
          "minHeight": "128px"
        },
        "lg": {
          "minHeight": "160px"
        }
      },
      "states": {
        "default": {
          "field": "w-full resize-y bg-transparent text-semantic-text-primary placeholder:text-semantic-text-muted focus:outline-none"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:border-semantic-border-accented"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus focus-within:ring-offset-2 focus-within:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "root": "opacity-50 pointer-events-none"
        },
        "selected": {
          "root": "data-[selected=true]:border-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Maintain visible focus boundary while preserving native caret visibility.",
        "notes": [
          "Provide character count when limits are enforced.",
          "Ensure helper text announces validation state."
        ]
      }
    },
    "select": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.text.primary",
        "semantic.border.default",
        "semantic.border.focus",
        "tokens.radius.xl",
        "tokens.spacing.3",
        "tokens.spacing.4"
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
            "trigger": "bg-semantic-bg-elevated border border-semantic-border-default",
            "content": "bg-semantic-bg-elevated border border-semantic-border-default"
          },
          "error": {
            "trigger": "bg-semantic-bg-elevated border border-danger-500"
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
          "trigger": "inline-flex items-center justify-between gap-2 transition-colors duration-base ease-standard"
        },
        "hover": {
          "trigger": "hover:border-semantic-border-accented",
          "item": "hover:bg-semantic-bg-accented"
        },
        "active": {
          "item": "active:bg-semantic-bg-accented"
        },
        "focusVisible": {
          "trigger": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus focus-visible:ring-offset-2 focus-visible:ring-offset-semantic-bg-base"
        },
        "disabled": {
          "trigger": "opacity-50 pointer-events-none"
        },
        "selected": {
          "item": "data-[state=checked]:bg-semantic-bg-accented data-[state=checked]:text-semantic-text-highlighted"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Visible trigger focus ring and selected-state indicator in listbox.",
        "notes": [
          "Use role=listbox and option semantics.",
          "Support keyboard navigation and typeahead."
        ]
      }
    },
    "card": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.bg.elevated",
        "semantic.bg.accented",
        "semantic.border.default",
        "semantic.text.primary",
        "tokens.radius.2xl",
        "tokens.spacing.4",
        "tokens.shadow.sm"
      ],
      "slots": [
        "root",
        "header",
        "body",
        "footer"
      ],
      "defaultVariants": {
        "surface": "elevated",
        "padding": "md"
      },
      "variants": {
        "surface": {
          "base": {
            "root": "bg-semantic-bg-base border border-semantic-border-default"
          },
          "elevated": {
            "root": "bg-semantic-bg-elevated border border-semantic-border-default shadow-sm"
          },
          "accented": {
            "root": "bg-semantic-bg-accented border border-semantic-border-accented"
          }
        },
        "padding": {
          "sm": {
            "root": "p-3"
          },
          "md": {
            "root": "p-4"
          },
          "lg": {
            "root": "p-6"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "120px"
        },
        "md": {
          "minHeight": "160px"
        },
        "lg": {
          "minHeight": "220px"
        }
      },
      "states": {
        "default": {
          "root": "rounded-2xl text-semantic-text-primary"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:scale-[0.995]"
        },
        "focusVisible": {
          "root": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-50 pointer-events-none"
        },
        "selected": {
          "root": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Interactive cards require visible keyboard focus style and non-color selection affordance.",
        "notes": [
          "Avoid using card-as-button without role and keyboard handlers.",
          "Preserve heading hierarchy in card headers."
        ]
      }
    },
    "badge": {
      "requiredTokenRefs": [
        "semantic.status.success",
        "semantic.status.warning",
        "semantic.status.danger",
        "semantic.status.info",
        "tokens.radius.full",
        "tokens.spacing.2",
        "tokens.spacing.3"
      ],
      "slots": [
        "root",
        "dot",
        "label"
      ],
      "defaultVariants": {
        "intent": "info",
        "size": "md"
      },
      "variants": {
        "intent": {
          "info": {
            "root": "bg-secondary-100 text-secondary-700"
          },
          "success": {
            "root": "bg-success-100 text-success-500"
          },
          "warning": {
            "root": "bg-warning-100 text-warning-700"
          },
          "danger": {
            "root": "bg-danger-100 text-danger-500"
          }
        },
        "size": {
          "sm": {
            "root": "h-5 px-2 text-xs rounded-full"
          },
          "md": {
            "root": "h-6 px-2.5 text-sm rounded-full"
          },
          "lg": {
            "root": "h-7 px-3 text-sm rounded-full"
          }
        }
      },
      "sizes": {
        "sm": {
          "minHeight": "20px"
        },
        "md": {
          "minHeight": "24px"
        },
        "lg": {
          "minHeight": "28px"
        }
      },
      "states": {
        "default": {
          "root": "inline-flex items-center gap-1.5 font-medium"
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
          "root": "data-[selected=true]:ring-1 data-[selected=true]:ring-current"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "24px",
        "focusRule": "When badge is interactive, provide focus ring and role=button semantics.",
        "notes": [
          "Use icon+text for status when color ambiguity is possible."
        ]
      }
    },
    "alert": {
      "requiredTokenRefs": [
        "semantic.status.info",
        "semantic.status.success",
        "semantic.status.warning",
        "semantic.status.danger",
        "tokens.radius.xl",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "icon",
        "title",
        "description",
        "actions"
      ],
      "defaultVariants": {
        "intent": "info",
        "appearance": "soft"
      },
      "variants": {
        "intent": {
          "info": {
            "root": "bg-secondary-100 border border-secondary-300 text-secondary-700"
          },
          "success": {
            "root": "bg-success-100 border border-success-500 text-success-500"
          },
          "warning": {
            "root": "bg-warning-100 border border-warning-500 text-warning-700"
          },
          "danger": {
            "root": "bg-danger-100 border border-danger-500 text-danger-500"
          }
        },
        "appearance": {
          "soft": {
            "root": "rounded-xl"
          },
          "solid": {
            "root": "rounded-xl text-semantic-text-inverted"
          }
        }
      },
      "sizes": {
        "md": {
          "minHeight": "56px"
        }
      },
      "states": {
        "default": {
          "root": "grid grid-cols-[auto_1fr] gap-3 p-4"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:brightness-95"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
        },
        "disabled": {
          "root": "opacity-50"
        },
        "selected": {
          "root": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [
        {
          "when": {
            "intent": "danger",
            "appearance": "solid"
          },
          "classes": {
            "root": "bg-danger-500 border-danger-500"
          }
        }
      ],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Critical alerts should use role=alert and keep dismiss controls keyboard reachable.",
        "notes": [
          "Do not suppress icon + text redundancy for high-severity alerts."
        ]
      }
    },
    "toast": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.border.default",
        "semantic.text.primary",
        "tokens.radius.xl",
        "tokens.shadow.md",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "icon",
        "title",
        "description",
        "close"
      ],
      "defaultVariants": {
        "intent": "info"
      },
      "variants": {
        "intent": {
          "info": {
            "icon": "text-secondary-500"
          },
          "success": {
            "icon": "text-success-500"
          },
          "warning": {
            "icon": "text-warning-700"
          },
          "danger": {
            "icon": "text-danger-500"
          }
        }
      },
      "sizes": {
        "md": {
          "minHeight": "64px"
        }
      },
      "states": {
        "default": {
          "root": "bg-semantic-bg-elevated border border-semantic-border-default rounded-xl shadow-md p-4"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:scale-[0.995]"
        },
        "focusVisible": {
          "root": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
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
        "focusRule": "Use role=status for non-critical toasts and role=alert for urgent errors.",
        "notes": [
          "Pause auto-dismiss on hover/focus for keyboard users."
        ]
      }
    },
    "navigation-header": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.border.default",
        "semantic.text.primary",
        "semantic.text.muted",
        "tokens.spacing.4",
        "tokens.spacing.6"
      ],
      "slots": [
        "root",
        "brand",
        "nav",
        "item",
        "actions"
      ],
      "defaultVariants": {
        "density": "comfortable"
      },
      "variants": {
        "density": {
          "compact": {
            "root": "h-14 px-4"
          },
          "comfortable": {
            "root": "h-16 px-6"
          }
        }
      },
      "sizes": {
        "default": {
          "minHeight": "56px"
        }
      },
      "states": {
        "default": {
          "root": "sticky top-0 z-50 flex items-center justify-between bg-semantic-bg-base border-b border-semantic-border-default"
        },
        "hover": {
          "item": "hover:text-semantic-text-highlighted"
        },
        "active": {
          "item": "data-[active=true]:text-semantic-text-highlighted"
        },
        "focusVisible": {
          "item": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "item": "opacity-50 pointer-events-none"
        },
        "selected": {
          "item": "data-[selected=true]:text-semantic-text-highlighted"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Top-level nav items require visible focus and current-page indicators.",
        "notes": [
          "Use aria-current=page on active route links."
        ]
      }
    },
    "navigation-sidebar": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.bg.elevated",
        "semantic.border.default",
        "semantic.text.primary",
        "semantic.text.muted",
        "tokens.spacing.3",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "group",
        "item",
        "icon",
        "label",
        "footer"
      ],
      "defaultVariants": {
        "state": "expanded"
      },
      "variants": {
        "state": {
          "expanded": {
            "root": "w-64"
          },
          "collapsed": {
            "root": "w-20",
            "label": "sr-only"
          }
        }
      },
      "sizes": {
        "default": {
          "minHeight": "100vh"
        }
      },
      "states": {
        "default": {
          "root": "bg-semantic-bg-base border-r border-semantic-border-default p-3",
          "item": "flex items-center gap-3 rounded-lg px-3 py-2 text-semantic-text-muted"
        },
        "hover": {
          "item": "hover:bg-semantic-bg-elevated hover:text-semantic-text-primary"
        },
        "active": {
          "item": "data-[active=true]:bg-semantic-bg-accented data-[active=true]:text-semantic-text-highlighted"
        },
        "focusVisible": {
          "item": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "item": "opacity-50 pointer-events-none"
        },
        "selected": {
          "item": "data-[selected=true]:bg-semantic-bg-accented"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Collapsed nav must preserve keyboard discoverability via tooltips or accessible labels.",
        "notes": [
          "Do not hide active location cues when collapsed."
        ]
      }
    },
    "modal": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.border.default",
        "semantic.text.primary",
        "tokens.radius.2xl",
        "tokens.shadow.lg",
        "tokens.spacing.6"
      ],
      "slots": [
        "overlay",
        "panel",
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
            "panel": "max-w-md"
          },
          "md": {
            "panel": "max-w-xl"
          },
          "lg": {
            "panel": "max-w-3xl"
          }
        }
      },
      "sizes": {
        "sm": {
          "maxWidth": "28rem"
        },
        "md": {
          "maxWidth": "36rem"
        },
        "lg": {
          "maxWidth": "48rem"
        }
      },
      "states": {
        "default": {
          "overlay": "fixed inset-0 bg-black/40 backdrop-blur-sm",
          "panel": "bg-semantic-bg-elevated border border-semantic-border-default rounded-2xl shadow-lg"
        },
        "hover": {
          "close": "hover:bg-semantic-bg-accented"
        },
        "active": {
          "close": "active:bg-semantic-bg-accented"
        },
        "focusVisible": {
          "close": "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-semantic-border-focus"
        },
        "disabled": {
          "close": "opacity-50 pointer-events-none"
        },
        "selected": {
          "panel": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Trap focus within modal and restore focus to trigger on close.",
        "notes": [
          "Use aria-modal=true and label the dialog title."
        ]
      }
    },
    "drawer": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.border.default",
        "tokens.shadow.lg",
        "tokens.spacing.6",
        "tokens.radius.2xl"
      ],
      "slots": [
        "overlay",
        "panel",
        "header",
        "body",
        "footer"
      ],
      "defaultVariants": {
        "side": "right",
        "size": "md"
      },
      "variants": {
        "side": {
          "left": {
            "panel": "left-0"
          },
          "right": {
            "panel": "right-0"
          }
        },
        "size": {
          "sm": {
            "panel": "w-80"
          },
          "md": {
            "panel": "w-96"
          },
          "lg": {
            "panel": "w-[32rem]"
          }
        }
      },
      "sizes": {
        "sm": {
          "width": "20rem"
        },
        "md": {
          "width": "24rem"
        },
        "lg": {
          "width": "32rem"
        }
      },
      "states": {
        "default": {
          "overlay": "fixed inset-0 bg-black/40",
          "panel": "fixed top-0 h-full bg-semantic-bg-elevated border-l border-semantic-border-default shadow-lg"
        },
        "hover": {
          "panel": "hover:border-semantic-border-accented"
        },
        "active": {
          "panel": "active:border-semantic-border-accented"
        },
        "focusVisible": {
          "panel": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
        },
        "disabled": {
          "panel": "opacity-50 pointer-events-none"
        },
        "selected": {
          "panel": "data-[selected=true]:ring-2 data-[selected=true]:ring-semantic-border-focus"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Maintain focus trap and close on Escape with clear close affordance.",
        "notes": [
          "Provide inert background behavior while open."
        ]
      }
    },
    "data-table": {
      "requiredTokenRefs": [
        "semantic.bg.base",
        "semantic.bg.elevated",
        "semantic.border.default",
        "semantic.border.accented",
        "semantic.text.primary",
        "semantic.text.muted",
        "tokens.spacing.3",
        "tokens.spacing.4",
        "tokens.radius.xl"
      ],
      "slots": [
        "root",
        "table",
        "thead",
        "th",
        "tr",
        "td",
        "caption",
        "empty"
      ],
      "defaultVariants": {
        "density": "md",
        "striped": "off"
      },
      "variants": {
        "density": {
          "sm": {
            "th": "py-2 px-3 text-xs",
            "td": "py-2 px-3 text-sm"
          },
          "md": {
            "th": "py-3 px-4 text-sm",
            "td": "py-3 px-4 text-sm"
          },
          "lg": {
            "th": "py-4 px-5 text-base",
            "td": "py-4 px-5 text-base"
          }
        },
        "striped": {
          "off": {
            "tr": ""
          },
          "on": {
            "tr": "odd:bg-semantic-bg-base even:bg-semantic-bg-elevated"
          }
        }
      },
      "sizes": {
        "sm": {
          "rowHeight": "40px"
        },
        "md": {
          "rowHeight": "48px"
        },
        "lg": {
          "rowHeight": "56px"
        }
      },
      "states": {
        "default": {
          "root": "overflow-x-auto rounded-xl border border-semantic-border-default",
          "thead": "bg-semantic-bg-elevated",
          "th": "text-left font-medium text-semantic-text-muted",
          "td": "text-semantic-text-primary border-t border-semantic-border-default"
        },
        "hover": {
          "tr": "hover:bg-semantic-bg-accented"
        },
        "active": {
          "tr": "data-[active=true]:bg-semantic-bg-accented"
        },
        "focusVisible": {
          "tr": "focus-within:ring-2 focus-within:ring-semantic-border-focus"
        },
        "disabled": {
          "tr": "opacity-50"
        },
        "selected": {
          "tr": "data-[selected=true]:bg-semantic-bg-accented"
        }
      },
      "compoundVariants": [],
      "a11y": {
        "minTargetSize": "44px",
        "focusRule": "Keyboard-focusable rows need visible row outline and equivalent non-hover affordance.",
        "notes": [
          "Use scope=col for header cells.",
          "Provide sr-only sortable state labels for sortable columns."
        ]
      }
    },
    "stat-card": {
      "requiredTokenRefs": [
        "semantic.bg.elevated",
        "semantic.border.default",
        "semantic.text.primary",
        "semantic.text.muted",
        "semantic.status.success",
        "semantic.status.danger",
        "tokens.radius.xl",
        "tokens.spacing.4"
      ],
      "slots": [
        "root",
        "label",
        "value",
        "delta",
        "meta"
      ],
      "defaultVariants": {
        "trend": "neutral"
      },
      "variants": {
        "trend": {
          "positive": {
            "delta": "text-success-500"
          },
          "negative": {
            "delta": "text-danger-500"
          },
          "neutral": {
            "delta": "text-semantic-text-muted"
          }
        }
      },
      "sizes": {
        "md": {
          "minHeight": "112px"
        }
      },
      "states": {
        "default": {
          "root": "rounded-xl border border-semantic-border-default bg-semantic-bg-elevated p-4",
          "label": "text-sm text-semantic-text-muted",
          "value": "text-2xl font-semibold text-semantic-text-highlighted",
          "meta": "text-xs text-semantic-text-dimmed"
        },
        "hover": {
          "root": "hover:border-semantic-border-accented"
        },
        "active": {
          "root": "active:scale-[0.995]"
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
        "focusRule": "When stat cards are interactive, expose role/button semantics and visible focus treatment.",
        "notes": [
          "Do not use color as sole indicator for trend; include +/- symbols or text."
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
      "detected": "ABC Whyte",
      "confidence": "likely paid",
      "freeAlternatives": [
        "Inter",
        "Manrope",
        "Plus Jakarta Sans"
      ],
      "notes": "ABC Whyte is loaded as a hosted WOFF2 asset on InjHub; licensing details are not public in the fetched assets. Inter is the closest neutral UI substitute."
    },
    {
      "detected": "ABC Whyte Mono",
      "confidence": "likely paid",
      "freeAlternatives": [
        "IBM Plex Mono",
        "JetBrains Mono",
        "Source Code Pro"
      ],
      "notes": "Mono companion to ABC Whyte appears in hosted assets; IBM Plex Mono is the most practical width/tone replacement for UI code labels."
    },
    {
      "detected": "Proxima Nova",
      "confidence": "likely paid",
      "freeAlternatives": [
        "Inter",
        "Source Sans 3",
        "Plus Jakarta Sans"
      ],
      "notes": "Proxima Nova family files are present in CSS bundle. Inter and Source Sans 3 provide similar readability and broad weight coverage."
    },
    {
      "detected": "Inter",
      "confidence": "free/open-source",
      "freeAlternatives": [
        "Inter",
        "Manrope",
        "Public Sans"
      ],
      "notes": "Inter is explicitly loaded in the production CSS and is open-source, making it safe for direct reuse."
    }
  ]
}
```

## assumptions.md
```md
- Scope is the full InjHub product surface (`/stake`, `/wallet`, `/governance`, `/community-buyback`, `/ecosystem`), not only staking flows.
- Strict clone means token values and interaction semantics are preserved, while layout-level reconstruction remains componentized and reusable.
- Light and dark mode are both modeled, with dark set as default because the boot script falls back to `dark` when no preference exists.
- Where runtime semantic variables (`--ui-color-*`, `--ui-primary`, `--ui-success`, etc.) are referenced but not explicitly declared in fetched CSS, mappings are inferred and documented in `design-system.json` evidence.
- CSS-observed values are treated as authoritative due limited screenshot rendering in this execution environment.
- `ui-secondary` and `ui-info` are inferred onto the observed secondary/sky family because no direct declarations were retrievable.
- Component recipes are token-driven; they avoid page-specific naming unless the token is part of Injective brand identity.
```

## downstream-ai-prompt.md
```md
You are given `design-system.json` and `component-blueprints.json`.
Apply these defaults even if the user does not explicitly request them:
1. Use only these two files as source of truth.
2. Never rename token keys.
3. Never silently create new tokens.
4. If a required token is missing, continue with best-effort component code and append a separate `Missing Token Report` section.

Implementation rules:
1. Resolve semantic token references first, then mode-specific mappings (`light`/`dark`), then emit classes.
2. Keep variant groups orthogonal; use `compoundVariants` only when interaction between variant axes is required.
3. Preserve accessibility constraints from each component blueprint (`a11y` block), including focus treatment and minimum target size.
4. Do not collapse status variants (`success`, `warning`, `danger`, `info`) into one generic style.

Return:
1. Component code
2. Variant usage examples
3. Missing Token Report (if any missing token exists)
```
