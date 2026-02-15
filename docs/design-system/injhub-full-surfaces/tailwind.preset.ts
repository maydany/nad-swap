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
