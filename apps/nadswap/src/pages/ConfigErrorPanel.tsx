import { envErrorMessage } from "../lib/env";

export const ConfigErrorPanel = () => {
  return (
    <section className="rounded-2xl border border-rose-300 bg-rose-50 p-5 text-sm text-rose-900">
      <h2 className="text-lg font-semibold">NadSwap config error</h2>
      <p className="mt-2">{envErrorMessage}</p>
      <p className="mt-2">Run `pnpm env:sync:nadswap` after local deploy.</p>
    </section>
  );
};
