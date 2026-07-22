/** HomeOps HTTP server. */

import express from "express";
import { registerWorkloadRoutes } from "./routes/workloads.js";

const application = express();
const port = Number(process.env.HOMEOPS_PORT ?? "4174");

application.disable("x-powered-by");
application.use(express.json({ limit: "64kb" }));
registerWorkloadRoutes(application);
application.use((error: unknown, _request: express.Request, response: express.Response, _next: express.NextFunction) => {
  console.error("HomeOps request failed", error);
  response.status(500).json({ error: "request failed" });
});

application.listen(port, "127.0.0.1", () => {
  console.log(`HomeOps API listening on http://127.0.0.1:${port}`);
});
