export interface WebhookRequest {
  url: string;
  body: string;
}

export function createWebhookRequest(url: string, body: string): WebhookRequest {
  return { url, body };
}
