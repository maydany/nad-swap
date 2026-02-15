import { lensAbi, type AddressHex } from "@nadswap/contracts";
import { useReadContract } from "wagmi";

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
  statuses: LensPairViewStatuses | null;
  overallStatus: LensStatus | null;
  isFetching: boolean;
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<unknown>;
};

export const useLensPairView = ({ lensAddress, pairAddress, userAddress }: UseLensPairViewParams): LensPairViewState => {
  const canQuery = Boolean(userAddress);

  const { data, error, isFetching, isLoading, refetch } = useReadContract({
    address: lensAddress,
    abi: lensAbi,
    functionName: "getPairView",
    args: [pairAddress, userAddress ?? ZERO_ADDRESS],
    query: {
      enabled: canQuery,
      refetchInterval: canQuery ? 15_000 : false
    }
  });

  const statuses = mapPairViewStatuses(data);

  return {
    canQuery,
    statuses,
    overallStatus: statuses?.overallStatus ?? null,
    isFetching,
    isLoading,
    error: error instanceof Error ? error.message : null,
    refetch: async () => refetch()
  };
};
