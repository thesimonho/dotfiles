import type { ResourceTemplate } from "./resource-template.js";

/** Render the stable identifying fields used by manifest previews. */
export function renderResourceIdentity(template: ResourceTemplate): string {
  return `${template.kind}/${template.namespace}`;
}
