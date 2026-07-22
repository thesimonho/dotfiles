import { useEffect, useState } from "react";
import type { WorkloadSummary } from "../domain/workloads";

export function App() {
  const [workloads, setWorkloads] = useState<WorkloadSummary[]>([]);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const visibleWorkloads = workloads.filter((workload) => workload.namespace !== "system");

  useEffect(() => {
    fetch("/api/workloads")
      .then((response) => {
        if (!response.ok) throw new Error("workloads request failed");
        return response.json() as Promise<WorkloadSummary[]>;
      })
      .then(setWorkloads)
      .catch(() => setErrorMessage("Workload inventory is temporarily unavailable."));
  }, []);

  return <>
    <header className="page-header">
      <p className="eyebrow">Homelab control plane</p>
      <h1>HomeOps</h1>
      <p>Observed Kubernetes state and GitOps readiness in one place.</p>
    </header>
    <section aria-labelledby="workloads-heading" className="panel">
      <h2 id="workloads-heading">Workloads</h2>
      {errorMessage ? <p role="alert">{errorMessage}</p> : null}
      <ul className="workload-grid">
        {visibleWorkloads.map((workload) => <li className="workload-card" key={`${workload.namespace}/${workload.name}`}>
          <span className={`health health-${workload.health}`}>{workload.health}</span>
          <h3>{workload.name}</h3>
          <p>{workload.namespace}</p>
          <p>{workload.readyReplicas}/{workload.desiredReplicas} ready</p>
          <code>{workload.image}</code>
        </li>)}
      </ul>
    </section>
  </>;
}
