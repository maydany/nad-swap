import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { TradeActionButton } from "./TradeActionButton";

const noop = vi.fn();

describe("TradeActionButton", () => {
  it("shows Switch button when network is wrong", () => {
    render(
      <TradeActionButton
        isConnected
        wrongNetwork
        needsApproval
        canSwap={false}
        isSwitching={false}
        isApproving={false}
        isSwapping={false}
        onSwitch={noop}
        onApprove={noop}
        onSwap={noop}
      />
    );

    expect(screen.getByRole("button", { name: "Switch to Local Anvil" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Approve USDT" })).not.toBeInTheDocument();
  });

  it("shows Approve when allowance is insufficient", () => {
    render(
      <TradeActionButton
        isConnected
        wrongNetwork={false}
        needsApproval
        canSwap={false}
        isSwitching={false}
        isApproving={false}
        isSwapping={false}
        onSwitch={noop}
        onApprove={noop}
        onSwap={noop}
      />
    );

    expect(screen.getByRole("button", { name: "Approve USDT" })).toBeInTheDocument();
  });

  it("shows Swap when allowance is enough", () => {
    const onSwap = vi.fn();

    render(
      <TradeActionButton
        isConnected
        wrongNetwork={false}
        needsApproval={false}
        canSwap
        isSwitching={false}
        isApproving={false}
        isSwapping={false}
        onSwitch={noop}
        onApprove={noop}
        onSwap={onSwap}
      />
    );

    const button = screen.getByRole("button", { name: "Swap USDT -> NAD" });
    fireEvent.click(button);
    expect(onSwap).toHaveBeenCalledTimes(1);
  });
});
