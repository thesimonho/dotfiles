/** Resource templates shared by dashboard and API presentation layers. */

export interface ResourceTemplate {
  kind: "Deployment" | "StatefulSet";
  namespace: string;
  labels: Record<string, string>;
}

export function createResourceTemplate(
  kind: ResourceTemplate["kind"],
  namespace: string,
): ResourceTemplate {
  return {
    kind,
    namespace,
    labels: { "app.kubernetes.io/managed-by": "homeops" },
  };
}
