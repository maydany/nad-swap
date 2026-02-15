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
};

const baseClassName = "w-full rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-60";

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
  onSwap
}: TradeActionButtonProps) => {
  if (!isConnected) {
    return (
      <button type="button" disabled className={`${baseClassName} bg-slate-500`}>
        Connect wallet first
      </button>
    );
  }

  if (wrongNetwork) {
    return (
      <button type="button" onClick={onSwitch} disabled={isSwitching} className={`${baseClassName} bg-amber-600`}>
        {isSwitching ? "Switching..." : "Switch to Local Anvil"}
      </button>
    );
  }

  if (needsApproval) {
    return (
      <button type="button" onClick={onApprove} disabled={isApproving} className={`${baseClassName} bg-slate-900`}>
        {isApproving ? "Approving..." : "Approve USDT"}
      </button>
    );
  }

  return (
    <button type="button" onClick={onSwap} disabled={!canSwap || isSwapping} className={`${baseClassName} bg-cyan-700`}>
      {isSwapping ? "Swapping..." : "Swap USDT -> NAD"}
    </button>
  );
};
