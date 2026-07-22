import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import "./styles.css";

const rootElement = document.getElementById("root");
if (rootElement === null) {
  throw new Error("HomeOps root element is missing");
}
createRoot(rootElement).render(<StrictMode><App /></StrictMode>);
