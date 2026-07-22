/** HTTP route for workload summaries. */

import type { Express } from "express";
import { summarizeWorkload } from "../../domain/workloads.js";
import { loadObservedWorkloads } from "../cluster/observedWorkloads.js";

export function registerWorkloadRoutes(application: Express): void {
  application.get("/api/workloads", async (_request, response, next) => {
    try {
      response.json((await loadObservedWorkloads()).map(summarizeWorkload));
    } catch (error) {
      next(error);
    }
  });
}
