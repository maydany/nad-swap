import { useState } from "react";
import { useAccount, useChainId, useConnect, useDisconnect } from "wagmi";

type WalletPanelProps = {
  targetChainId: number;
};

const shortAddress = (value: string) => `${value.slice(0, 6)}...${value.slice(-4)}`;

export const WalletPanel = ({ targetChainId }: WalletPanelProps) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { connectAsync, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const isWrongNetwork = isConnected && chainId !== targetChainId;

  const onConnect = async () => {
    setErrorMessage(null);
    try {
      const injectedConnector = connectors.find((connector) => connector.id === "injected") ?? connectors[0];
      if (!injectedConnector) {
        throw new Error("No wallet connector found.");
      }
      await connectAsync({ connector: injectedConnector, chainId: targetChainId });
    } catch (error) {
      console.error(error);
      setErrorMessage(error instanceof Error ? error.message : "Wallet connection failed.");
    }
  };

  return (
    <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Wallet</p>
          {isConnected && address ? (
            <p className="text-sm font-semibold text-slate-800">{shortAddress(address)}</p>
          ) : (
            <p className="text-sm text-slate-700">Not connected</p>
          )}
          <p className="text-xs text-slate-500">Network: {chainId}</p>
        </div>

        {isConnected ? (
          <button
            type="button"
            onClick={() => disconnect()}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Disconnect
          </button>
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

      {isWrongNetwork && (
        <p className="mt-3 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
          Wrong network detected. Switch to chain id {targetChainId}.
        </p>
      )}

      {errorMessage && (
        <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{errorMessage}</p>
      )}
    </section>
  );
};
