import { erc20Abi, routerAbi, type AddressHex } from "@nadswap/contracts";
import { useMemo, useState } from "react";
import { formatUnits, parseUnits } from "viem";
import {
  useAccount,
  useChainId,
  usePublicClient,
  useReadContract,
  useSwitchChain,
  useWriteContract
} from "wagmi";

import type { LensStatus } from "../lens/types";
import { TradeActionButton } from "./TradeActionButton";
import { applySlippageBps } from "./math";

const DEFAULT_SLIPPAGE_BPS = 50;

type SwapCardProps = {
  expectedChainId: number;
  routerAddress: AddressHex;
  usdtAddress: AddressHex;
  nadAddress: AddressHex;
  lensStatus: LensStatus | null;
};

const formatAmount = (value: bigint | null, decimals: number): string => {
  if (value === null) {
    return "-";
  }

  return Number(formatUnits(value, decimals)).toLocaleString(undefined, {
    maximumFractionDigits: 6
  });
};

const normalizeError = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }
  return "Unknown transaction error";
};

export const SwapCard = ({ expectedChainId, routerAddress, usdtAddress, nadAddress, lensStatus }: SwapCardProps) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChainAsync } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient({ chainId: expectedChainId });

  const [amountIn, setAmountIn] = useState("0");
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const [isSwitching, setIsSwitching] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);

  const wrongNetwork = isConnected && chainId !== expectedChainId;
  const lensBlocksTrade = lensStatus !== null && lensStatus !== 0;

  const { data: inSymbol = "USDT" } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "symbol"
  });

  const { data: outSymbol = "NAD" } = useReadContract({
    address: nadAddress,
    abi: erc20Abi,
    functionName: "symbol"
  });

  const { data: inDecimals = 18 } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "decimals"
  });

  const { data: outDecimals = 18 } = useReadContract({
    address: nadAddress,
    abi: erc20Abi,
    functionName: "decimals"
  });

  const parsedAmountIn = useMemo(() => {
    try {
      if (!amountIn || Number(amountIn) <= 0) {
        return null;
      }
      return parseUnits(amountIn, inDecimals);
    } catch {
      return null;
    }
  }, [amountIn, inDecimals]);

  const path = [usdtAddress, nadAddress] as const;

  const {
    data: allowance = 0n,
    refetch: refetchAllowance,
    error: allowanceError
  } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "allowance",
    args: [address ?? "0x0000000000000000000000000000000000000000", routerAddress],
    query: {
      enabled: isConnected
    }
  });

  const { data: balanceIn = 0n, refetch: refetchBalanceIn } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [address ?? "0x0000000000000000000000000000000000000000"],
    query: {
      enabled: isConnected
    }
  });

  const { data: balanceOut = 0n, refetch: refetchBalanceOut } = useReadContract({
    address: nadAddress,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [address ?? "0x0000000000000000000000000000000000000000"],
    query: {
      enabled: isConnected
    }
  });

  const quoteEnabled = Boolean(isConnected && parsedAmountIn && !wrongNetwork);

  const {
    data: amountsOut,
    error: quoteError,
    isFetching: isQuoteFetching,
    refetch: refetchQuote
  } = useReadContract({
    address: routerAddress,
    abi: routerAbi,
    functionName: "getAmountsOut",
    args: [parsedAmountIn ?? 0n, path],
    query: {
      enabled: quoteEnabled
    }
  });

  const quotedOut = Array.isArray(amountsOut) && amountsOut.length > 0 ? amountsOut[amountsOut.length - 1] : null;
  const amountOutMin = quotedOut !== null ? applySlippageBps(quotedOut, DEFAULT_SLIPPAGE_BPS) : null;

  const needsApproval = Boolean(parsedAmountIn && allowance < parsedAmountIn);

  const canSwap =
    isConnected &&
    !wrongNetwork &&
    !needsApproval &&
    !lensBlocksTrade &&
    parsedAmountIn !== null &&
    amountOutMin !== null &&
    Number(amountIn) > 0;

  const onSwitch = async () => {
    setActionError(null);
    setActionMessage(null);

    if (!switchChainAsync) {
      setActionError("Wallet connector does not support programmatic chain switch.");
      return;
    }

    setIsSwitching(true);
    try {
      await switchChainAsync({ chainId: expectedChainId });
      setActionMessage("Network switched.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwitching(false);
    }
  };

  const onApprove = async () => {
    if (!parsedAmountIn) {
      return;
    }

    setActionError(null);
    setActionMessage(null);
    setIsApproving(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const txHash = await writeContractAsync({
        address: usdtAddress,
        abi: erc20Abi,
        functionName: "approve",
        args: [routerAddress, parsedAmountIn]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await refetchAllowance();
      setActionMessage("Approve transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsApproving(false);
    }
  };

  const onSwap = async () => {
    if (!address || !parsedAmountIn || amountOutMin === null) {
      return;
    }

    setActionError(null);
    setActionMessage(null);
    setIsSwapping(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const deadline = BigInt(Math.floor(Date.now() / 1000) + 600);

      const txHash = await writeContractAsync({
        address: routerAddress,
        abi: routerAbi,
        functionName: "swapExactTokensForTokens",
        args: [parsedAmountIn, amountOutMin, path, address, deadline]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([refetchAllowance(), refetchBalanceIn(), refetchBalanceOut(), refetchQuote()]);
      setActionMessage("Swap transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwapping(false);
    }
  };

  return (
    <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
      <h2 className="text-sm font-semibold text-slate-900">USDT → NAD Swap</h2>

      <div className="mt-4 grid gap-2">
        <label htmlFor="amount-in" className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Amount In ({inSymbol})
        </label>
        <input
          id="amount-in"
          value={amountIn}
          onChange={(event) => setAmountIn(event.target.value)}
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
          placeholder="0.0"
          inputMode="decimal"
        />
      </div>

      <div className="mt-4 grid gap-2 rounded-lg bg-slate-100 p-3 text-sm text-slate-700">
        <p>Quote ({outSymbol}): {isQuoteFetching ? "Fetching..." : formatAmount(quotedOut, outDecimals)}</p>
        <p>amountOutMin (0.5% slippage): {formatAmount(amountOutMin, outDecimals)}</p>
        <p>
          Allowance: {formatAmount(allowance, inDecimals)} {inSymbol}
        </p>
        <p>
          Balance: {formatAmount(balanceIn, inDecimals)} {inSymbol} / {formatAmount(balanceOut, outDecimals)} {outSymbol}
        </p>
      </div>

      {lensBlocksTrade && (
        <p className="mt-4 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
          Lens status is not OK. Trade is temporarily blocked.
        </p>
      )}

      {quoteError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">Quote error: {quoteError.message}</p>
      )}

      {allowanceError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">
          Allowance read error: {allowanceError.message}
        </p>
      )}

      {actionError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">{actionError}</p>
      )}

      {actionMessage && (
        <p className="mt-4 rounded-lg bg-emerald-100 px-3 py-2 text-sm text-emerald-900">{actionMessage}</p>
      )}

      <div className="mt-4">
        <TradeActionButton
          isConnected={isConnected}
          wrongNetwork={wrongNetwork}
          needsApproval={needsApproval}
          canSwap={canSwap}
          isSwitching={isSwitching}
          isApproving={isApproving}
          isSwapping={isSwapping}
          onSwitch={() => void onSwitch()}
          onApprove={() => void onApprove()}
          onSwap={() => void onSwap()}
        />
      </div>
    </section>
  );
};
