import { buddyConfig } from "./config";

const storageKeys = {
  accessToken: "buddy.access-token",
  refreshToken: "buddy.refresh-token",
  codeVerifier: "buddy.code-verifier",
  mode: "buddy.session-mode",
} as const;

export type BuddySession = {
  mode: "live" | "preview";
  accessToken?: string;
};

type TokenResponse = {
  accessToken: string;
  refreshToken: string;
  ssoInfo?: string;
};

function base64URL(data: Uint8Array) {
  const binary = Array.from(data, (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function randomVerifier() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64URL(bytes);
}

async function codeChallenge(verifier: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier));
  return base64URL(new Uint8Array(digest));
}

export function getSession(): BuddySession | null {
  const mode = sessionStorage.getItem(storageKeys.mode);
  if (mode === "preview") return { mode };
  const accessToken = sessionStorage.getItem(storageKeys.accessToken);
  return mode === "live" && accessToken ? { mode, accessToken } : null;
}

export function startPreviewSession() {
  sessionStorage.setItem(storageKeys.mode, "preview");
  sessionStorage.removeItem(storageKeys.accessToken);
  sessionStorage.removeItem(storageKeys.refreshToken);
}

export async function beginSignIn() {
  const verifier = randomVerifier();
  sessionStorage.setItem(storageKeys.codeVerifier, verifier);
  const url = new URL(buddyConfig.authorizationURL);
  url.searchParams.set("codeChallenge", await codeChallenge(verifier));
  url.searchParams.set("redirect_uri", `${window.location.origin}/auth/callback`);
  window.location.assign(url);
}

export async function completeSignIn(sessionCode: string) {
  const verifier = sessionStorage.getItem(storageKeys.codeVerifier);
  if (!verifier) throw new Error("This sign-in attempt has expired. Please start again.");

  const response = await fetch(buddyConfig.tokenIssueURL, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      codeVerifier: base64URL(new TextEncoder().encode(verifier)),
      session: sessionCode,
    }),
  });
  if (!response.ok) throw new Error("SPARCS SSO could not complete this sign-in.");

  const tokens = (await response.json()) as TokenResponse;
  if (!tokens.accessToken || !tokens.refreshToken) throw new Error("The sign-in response was incomplete.");

  if (tokens.ssoInfo) {
    const bootstrap = await fetch(`${buddyConfig.feedBaseURL}/auth/bootstrap`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokens.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ sso_info: tokens.ssoInfo, session: sessionCode }),
    });
    if (!bootstrap.ok && bootstrap.status !== 409) {
      throw new Error("Buddy could not prepare your feed account.");
    }
  }

  sessionStorage.setItem(storageKeys.accessToken, tokens.accessToken);
  sessionStorage.setItem(storageKeys.refreshToken, tokens.refreshToken);
  sessionStorage.setItem(storageKeys.mode, "live");
  sessionStorage.removeItem(storageKeys.codeVerifier);
}

let refreshInFlight: Promise<string> | null = null;

async function refreshAccessToken() {
  if (refreshInFlight) return refreshInFlight;
  refreshInFlight = (async () => {
    const refreshToken = sessionStorage.getItem(storageKeys.refreshToken);
    if (!refreshToken) throw new Error("Your session has expired.");
    const response = await fetch(buddyConfig.tokenRefreshURL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    if (!response.ok) throw new Error("Your session has expired.");
    const tokens = (await response.json()) as TokenResponse;
    sessionStorage.setItem(storageKeys.accessToken, tokens.accessToken);
    sessionStorage.setItem(storageKeys.refreshToken, tokens.refreshToken);
    return tokens.accessToken;
  })().finally(() => {
    refreshInFlight = null;
  });
  return refreshInFlight;
}

export async function authorizedFetch(input: RequestInfo | URL, init: RequestInit = {}) {
  const accessToken = sessionStorage.getItem(storageKeys.accessToken);
  if (!accessToken) throw new Error("You are not signed in.");

  const request = (token: string) =>
    fetch(input, {
      ...init,
      headers: { ...init.headers, Authorization: `Bearer ${token}` },
    });

  let response = await request(accessToken);
  if (response.status === 401) response = await request(await refreshAccessToken());
  return response;
}

export function signOut() {
  Object.values(storageKeys).forEach((key) => sessionStorage.removeItem(key));
}
