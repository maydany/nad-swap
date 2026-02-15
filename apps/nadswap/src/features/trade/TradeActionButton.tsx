import type { MouseEventHandler } from "react";

type TradeActionButtonProps = {
  isConnected: boolean;
  wrongNetwork: boolean;
  needsApproval: boolean;
  canSwap: boolean;
  isSwitching: boolean;
  isApproving: boolean;
  isSwapping: boolean;
  onSwitch: MouseEventHandler<HTMLButtonElement>;
  onApprove: MouseEventHandler<HTMLButtonElement>;
  onSwap: MouseEventHandler<HTMLButtonElement>;
  approveLabel?: string;
  swapLabel?: string;
};

const baseClassName =
  "w-full rounded-xl px-4 py-3 text-base font-semibold text-white transition disabled:cursor-not-allowed disabled:opacity-60";

export const TradeActionButton = ({
  isConnected,
  wrongNetwork,
  needsApproval,
  canSwap,
  isSwitching,
  isApproving,
  isSwapping,
  onSwitch,
  onApprove,
  onSwap,
  approveLabel = "Approve token",
  swapLabel = "Swap"
}: TradeActionButtonProps) => {
  if (!isConnected) {
    return (
      <button type="button" disabled className={`${baseClassName} bg-slate-600`}>
        Connect wallet first
      </button>
    );
  }

  if (wrongNetwork) {
    return (
      <button type="button" onClick={onSwitch} disabled={isSwitching} className={`${baseClassName} bg-amber-600 hover:bg-amber-500`}>
        {isSwitching ? "Switching..." : "Switch to Local Anvil"}
      </button>
    );
  }

  if (needsApproval) {
    return (
      <button type="button" onClick={onApprove} disabled={isApproving} className={`${baseClassName} bg-slate-900 hover:bg-slate-800`}>
        {isApproving ? "Approving..." : approveLabel}
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={onSwap}
      disabled={!canSwap || isSwapping}
      className={`${baseClassName} bg-cyan-700 hover:bg-cyan-600`}
    >
      {isSwapping ? "Swapping..." : swapLabel}
    </button>
  );
};
