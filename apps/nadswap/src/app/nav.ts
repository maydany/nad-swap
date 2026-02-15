export type AppRouteKey = "swap" | "pools" | "lens" | "admin";

export type NavItem = {
  key: AppRouteKey;
  label: string;
  to: string;
};

export const APP_ROUTES: Record<AppRouteKey, string> = {
  swap: "/swap",
  pools: "/pools",
  lens: "/lens",
  admin: "/admin"
};

export const NAV_ITEMS: readonly NavItem[] = [
  { key: "swap", label: "Swap", to: APP_ROUTES.swap },
  { key: "pools", label: "Pools", to: APP_ROUTES.pools },
  { key: "lens", label: "Lens", to: APP_ROUTES.lens },
  { key: "admin", label: "Admin", to: APP_ROUTES.admin }
];
