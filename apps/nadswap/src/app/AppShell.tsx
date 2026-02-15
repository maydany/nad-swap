import { useEffect, useRef, useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import { useAccount, useChainId, useConnect, useDisconnect } from "wagmi";

import { appEnv } from "../lib/env";
import { shortAddress } from "../lib/format";
import { NAV_ITEMS } from "./nav";

const navClassName = ({ isActive }: { isActive: boolean }) =>
  `nav-item ${isActive ? "nav-item-active" : "nav-item-idle"}`;

const networkBadgeClassName =
  "inline-flex items-center rounded-full border border-slate-300 bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700";

const resolveNetworkLabel = (chainId: number | undefined): string => {
  if (chainId === 31337) {
    return "Local";
  }
  if (chainId === 10143) {
    return "Monad Testnet";
  }
  if (chainId === 143) {
    return "Monad Mainnet";
  }
  if (chainId) {
    return `Chain ${chainId}`;
  }
  return "Network -";
};

export const AppShell = () => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { connectAsync, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();
  const [connectError, setConnectError] = useState<string | null>(null);
  const [walletMenuOpen, setWalletMenuOpen] = useState(false);
  const walletMenuRef = useRef<HTMLDivElement | null>(null);
  const networkLabel = resolveNetworkLabel(isConnected ? chainId : appEnv?.chainId);

  useEffect(() => {
    if (!walletMenuOpen) {
      return;
    }

    const onDocumentMouseDown = (event: MouseEvent) => {
      if (!walletMenuRef.current?.contains(event.target as Node)) {
        setWalletMenuOpen(false);
      }
    };

    const onDocumentKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setWalletMenuOpen(false);
      }
    };

    document.addEventListener("mousedown", onDocumentMouseDown);
    document.addEventListener("keydown", onDocumentKeyDown);

    return () => {
      document.removeEventListener("mousedown", onDocumentMouseDown);
      document.removeEventListener("keydown", onDocumentKeyDown);
    };
  }, [walletMenuOpen]);

  const onConnect = async () => {
    setConnectError(null);
    try {
      const injectedConnector = connectors.find((connector) => connector.id === "injected") ?? connectors[0];
      if (!injectedConnector) {
        throw new Error("No wallet connector found.");
      }
      await connectAsync({ connector: injectedConnector, chainId: appEnv?.chainId });
      setWalletMenuOpen(false);
    } catch (error) {
      console.error(error);
      setConnectError(error instanceof Error ? error.message : "Wallet connection failed.");
    }
  };

  const onDisconnect = () => {
    setWalletMenuOpen(false);
    disconnect();
  };

  return (
    <div className="min-h-screen">
      <header className="border-b border-slate-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex w-full max-w-3xl items-center gap-3 px-4 py-4 md:px-6">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">NADSWAP</p>

          <nav className="hidden flex-1 items-center justify-center gap-2 md:flex" aria-label="Desktop tabs">
            {NAV_ITEMS.map((item) => (
              <NavLink key={item.key} to={item.to} className={navClassName}>
                {item.label}
              </NavLink>
            ))}
          </nav>

          <div className="ml-auto flex items-center gap-2">
            <span className={networkBadgeClassName}>{networkLabel}</span>

            {isConnected && address ? (
              <div className="relative" ref={walletMenuRef}>
                <button
                  type="button"
                  onClick={() => setWalletMenuOpen((current) => !current)}
                  className="inline-flex items-center gap-2 rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  aria-haspopup="menu"
                  aria-expanded={walletMenuOpen}
                >
                  <span>{shortAddress(address)}</span>
                  <span className="text-xs text-slate-500">{walletMenuOpen ? "▲" : "▼"}</span>
                </button>

                {walletMenuOpen && (
                  <div
                    className="absolute right-0 top-full z-30 mt-2 min-w-[10rem] rounded-lg border border-slate-200 bg-white p-1 shadow-lg"
                    role="menu"
                  >
                    <button
                      type="button"
                      onClick={onDisconnect}
                      className="w-full rounded-md px-3 py-2 text-left text-sm font-medium text-slate-700 hover:bg-slate-50"
                      role="menuitem"
                    >
                      Disconnect
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <button
                type="button"
                onClick={onConnect}
                disabled={isPending}
                className="rounded-lg bg-slate-900 px-3 py-2 text-sm font-medium text-white disabled:opacity-60"
              >
                {isPending ? "Connecting..." : "Connect Wallet"}
              </button>
            )}
          </div>
        </div>

        {connectError && (
          <p className="mx-auto w-full max-w-3xl px-4 pb-3 text-right text-xs text-rose-700 md:px-6">{connectError}</p>
        )}
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
