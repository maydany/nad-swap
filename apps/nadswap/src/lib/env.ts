import { toAppContracts, type AddressHex, type AppAddresses, type AppContracts } from "@nadswap/contracts";
import { z } from "zod";

const REQUIRED_ENV_KEYS = [
  "VITE_FACTORY",
  "VITE_ROUTER",
  "VITE_LENS_ADDRESS",
  "VITE_WETH",
  "VITE_USDT",
  "VITE_NAD",
  "VITE_PAIR_USDT_NAD"
] as const;

const addressSchema = z.string().regex(/^0x[a-fA-F0-9]{40}$/, "must be a valid address");

const envSchema = z.object({
  VITE_FACTORY: addressSchema,
  VITE_ROUTER: addressSchema,
  VITE_LENS_ADDRESS: addressSchema,
  VITE_WETH: addressSchema,
  VITE_USDT: addressSchema,
  VITE_NAD: addressSchema,
  VITE_PAIR_USDT_NAD: addressSchema,
  VITE_CHAIN_ID: z.coerce.number().int().positive(),
  VITE_RPC_URL: z.string().min(1)
});

export type AppEnv = AppAddresses & {
  contracts: AppContracts;
};

export type ParseAppEnvResult =
  | {
      ok: true;
      value: AppEnv;
    }
  | {
      ok: false;
      missingKeys: readonly string[];
      message: string;
    };

const toAddressHex = (value: string): AddressHex => value as AddressHex;

const normalizeInput = (raw: Record<string, unknown>) => ({
  ...raw,
  VITE_CHAIN_ID: raw.VITE_CHAIN_ID ?? "31337",
  VITE_RPC_URL: raw.VITE_RPC_URL ?? "http://127.0.0.1:8545"
});

export const parseAppEnv = (raw: Record<string, unknown>): ParseAppEnvResult => {
  const missingKeys = REQUIRED_ENV_KEYS.filter((key) => {
    const value = raw[key];
    return typeof value !== "string" || value.trim() === "";
  });

  if (missingKeys.length > 0) {
    return {
      ok: false,
      missingKeys,
      message: `Missing required env keys: ${missingKeys.join(", ")}. Run pnpm env:sync:nadswap after ./deploy_local.sh.`
    };
  }

  const parsed = envSchema.safeParse(normalizeInput(raw));
  if (!parsed.success) {
    return {
      ok: false,
      missingKeys: [],
      message: parsed.error.issues.map((issue) => issue.message).join(" | ")
    };
  }

  const addresses: AppAddresses = {
    chainId: parsed.data.VITE_CHAIN_ID,
    rpcUrl: parsed.data.VITE_RPC_URL,
    factory: toAddressHex(parsed.data.VITE_FACTORY),
    router: toAddressHex(parsed.data.VITE_ROUTER),
    lens: toAddressHex(parsed.data.VITE_LENS_ADDRESS),
    weth: toAddressHex(parsed.data.VITE_WETH),
    usdt: toAddressHex(parsed.data.VITE_USDT),
    nad: toAddressHex(parsed.data.VITE_NAD),
    pairUsdtNad: toAddressHex(parsed.data.VITE_PAIR_USDT_NAD)
  };

  return {
    ok: true,
    value: {
      ...addresses,
      contracts: toAppContracts(addresses)
    }
  };
};

export const runtimeEnvResult = parseAppEnv(import.meta.env as Record<string, unknown>);
export const appEnv = runtimeEnvResult.ok ? runtimeEnvResult.value : null;
export const envErrorMessage = runtimeEnvResult.ok ? null : runtimeEnvResult.message;
