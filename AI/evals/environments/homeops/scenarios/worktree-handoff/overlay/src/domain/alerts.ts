export interface AlertState {
  name: string;
  silencedUntil?: string;
}

// The dashboard needs a helper here that determines whether the alert is silenced.
