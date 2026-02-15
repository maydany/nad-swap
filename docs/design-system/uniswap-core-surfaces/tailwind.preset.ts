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
