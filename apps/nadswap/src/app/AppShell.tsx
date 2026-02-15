import { NavLink, Outlet, useLocation } from "react-router-dom";
import { useAccount, useChainId } from "wagmi";

import { appEnv } from "../lib/env";
import { shortAddress } from "../lib/format";
import { NAV_ITEMS } from "./nav";

const resolvePageLabel = (pathname: string): string => {
  const matched = NAV_ITEMS.find((item) => pathname === item.to || pathname.startsWith(`${item.to}/`));
  return matched?.label ?? "Swap";
};

const navClassName = ({ isActive }: { isActive: boolean }) =>
  `nav-item ${isActive ? "nav-item-active" : "nav-item-idle"}`;

export const AppShell = () => {
  const location = useLocation();
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const pageLabel = resolvePageLabel(location.pathname);
  const expectedChainId = appEnv?.chainId;
  const wrongNetwork = Boolean(isConnected && expectedChainId && chainId !== expectedChainId);

  return (
    <div className="min-h-screen">
      <header className="border-b border-slate-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex w-full max-w-3xl items-start justify-between gap-4 px-4 py-4 md:px-6">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">NadSwap</p>
            <h1 className="mt-1 text-xl font-semibold text-slate-900">{pageLabel}</h1>
          </div>
          <div className="text-right text-xs text-slate-600">
            <p>Chain: {appEnv?.chainId ?? "N/A"}</p>
            <p>Router: {shortAddress(appEnv?.router)}</p>
            <p>Lens: {shortAddress(appEnv?.lens)}</p>
            <p>Wallet: {isConnected ? shortAddress(address) : "Disconnected"}</p>
            <p className={wrongNetwork ? "font-semibold text-amber-700" : "text-slate-600"}>
              {isConnected ? (wrongNetwork ? `Wrong network (${chainId})` : `Connected (${chainId})`) : "No active wallet"}
            </p>
          </div>
        </div>

        <nav className="mx-auto hidden w-full max-w-3xl gap-2 px-4 pb-3 md:flex md:px-6" aria-label="Desktop tabs">
          {NAV_ITEMS.map((item) => (
            <NavLink key={item.key} to={item.to} className={navClassName}>
              {item.label}
            </NavLink>
          ))}
        </nav>
      </header>

      <main className="app-page-main mx-auto flex w-full max-w-3xl flex-col gap-4 px-4 py-4 md:px-6">
        <Outlet />
      </main>

      <nav className="app-mobile-nav md:hidden" aria-label="Mobile bottom navigation">
        {NAV_ITEMS.map((item) => (
          <NavLink key={item.key} to={item.to} className={navClassName}>
            {item.label}
          </NavLink>
        ))}
      </nav>
    </div>
  );
};
