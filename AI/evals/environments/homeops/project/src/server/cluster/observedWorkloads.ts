/** Read the deterministic development cluster snapshot. */

import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import type { ObservedWorkload } from "../../domain/workloads.js";

const snapshotPath = fileURLToPath(new URL("../../../data/cluster-snapshot.json", import.meta.url));

export async function loadObservedWorkloads(): Promise<ObservedWorkload[]> {
  return JSON.parse(await readFile(snapshotPath, "utf8")) as ObservedWorkload[];
}
