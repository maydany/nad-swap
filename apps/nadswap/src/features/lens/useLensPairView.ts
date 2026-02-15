import { lensAbi, type AddressHex } from "@nadswap/contracts";
import { useReadContract } from "wagmi";

import { mapPairHealthView, type PairHealthViewModel } from "./pairHealthView";
import { mapPairViewStatuses } from "./resolveLensStatus";
import type { LensPairViewStatuses, LensStatus } from "./types";

const ZERO_ADDRESS: AddressHex = "0x0000000000000000000000000000000000000000";

type UseLensPairViewParams = {
  lensAddress: AddressHex;
  pairAddress: AddressHex;
  userAddress?: AddressHex;
};

export type LensPairViewState = {
  canQuery: boolean;
  hasUserAddress: boolean;
  statuses: LensPairViewStatuses | null;
  viewModel: PairHealthViewModel | null;
  overallStatus: LensStatus | null;
  isFetching: boolean;
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<unknown>;
};

export const useLensPairView = ({ lensAddress, pairAddress, userAddress }: UseLensPairViewParams): LensPairViewState => {
  const hasUserAddress = Boolean(userAddress);

  const { data, error, isFetching, isLoading, refetch } = useReadContract({
    address: lensAddress,
    abi: lensAbi,
    functionName: "getPairView",
    args: [pairAddress, userAddress ?? ZERO_ADDRESS],
    query: {
      enabled: true,
      refetchInterval: 15_000
    }
  });

  const viewModel = mapPairHealthView(data);
  const statuses = viewModel?.statuses ?? mapPairViewStatuses(data);

  return {
    canQuery: true,
    hasUserAddress,
    statuses,
    viewModel,
    overallStatus: statuses?.overallStatus ?? null,
    isFetching,
    isLoading,
    error: error instanceof Error ? error.message : null,
    refetch: async () => refetch()
  };
};
