/** Legacy server-side health classifier retained during the domain migration. */

interface LegacyReplicaState {
  desiredReplicas: number;
  readyReplicas: number;
}

export function isLegacyWorkloadHealthy(state: LegacyReplicaState): boolean {
  return state.readyReplicas >= state.desiredReplicas;
}
