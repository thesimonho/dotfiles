import { describe, expect, it } from "vitest";
import { deriveWorkloadHealth } from "../src/domain/workloads.js";

describe("deriveWorkloadHealth", () => {
  it("marks a ready workload as degraded when GitOps reconciliation failed", () => {
    expect(deriveWorkloadHealth({
      namespace: "homeops",
      name: "homeops-api",
      kind: "Deployment",
      desiredReplicas: 2,
      readyReplicas: 2,
      gitOpsReady: false,
      image: "registry.home.arpa/homeops:v1.8.3",
    })).toBe("degraded");
  });
});
