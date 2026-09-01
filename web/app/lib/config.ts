const production = import.meta.env.VITE_BUDDY_ENV === "production";

export const buddyConfig = {
  environment: production ? "production" : "development",
  authorizationURL:
    import.meta.env.VITE_BUDDY_AUTHORIZATION_URL ||
    (production
      ? "https://taxi.sparcs.org/api/auth/sparcsapp/login"
      : "https://taxi.dev.sparcs.org/api/auth/sparcsapp/login"),
  tokenIssueURL:
    import.meta.env.VITE_BUDDY_TOKEN_ISSUE_URL ||
    (production
      ? "https://taxi.sparcs.org/api/auth/sparcsapp/token/issue"
      : "https://taxi.dev.sparcs.org/api/auth/sparcsapp/token/issue"),
  tokenRefreshURL:
    import.meta.env.VITE_BUDDY_TOKEN_REFRESH_URL ||
    (production
      ? "https://taxi.sparcs.org/api/auth/sparcsapp/token/refresh"
      : "https://taxi.dev.sparcs.org/api/auth/sparcsapp/token/refresh"),
  feedBaseURL:
    import.meta.env.VITE_BUDDY_FEED_BASE_URL ||
    (production ? "https://buddy.sparcs.org/v1" : "https://buddy.dev.sparcs.org/v1"),
  previewEnabled:
    !production || import.meta.env.VITE_BUDDY_ENABLE_PREVIEW === "true",
} as const;
