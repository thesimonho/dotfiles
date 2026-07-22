/** Domain types and health derivation for observed Kubernetes workloads. */

export type WorkloadKind = "Deployment" | "DaemonSet" | "StatefulSet";
export type WorkloadHealth = "healthy" | "degraded" | "unavailable";

export interface ObservedWorkload {
  namespace: string;
  name: string;
  kind: WorkloadKind;
  desiredReplicas: number;
  readyReplicas: number;
  gitOpsReady: boolean;
  image: string;
}

export interface WorkloadSummary extends ObservedWorkload {
  health: WorkloadHealth;
}

export function deriveWorkloadHealth(workload: ObservedWorkload): WorkloadHealth {
  if (workload.readyReplicas === 0 && workload.desiredReplicas > 0) {
    return "unavailable";
  }
  if (workload.readyReplicas < workload.desiredReplicas) {
    return "degraded";
  }
  return "healthy";
}

export function summarizeWorkload(workload: ObservedWorkload): WorkloadSummary {
  return { ...workload, health: deriveWorkloadHealth(workload) };
}
