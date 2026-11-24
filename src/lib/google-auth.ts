export function googleAuthConfigured() {
  return Boolean(process.env.GOOGLE_CLIENT_ID?.trim() && process.env.GOOGLE_CLIENT_SECRET?.trim());
}

export function googleClientId() {
  return process.env.GOOGLE_CLIENT_ID?.trim() ?? "";
}

export function googleClientSecret() {
  return process.env.GOOGLE_CLIENT_SECRET?.trim() ?? "";
}

/** Optional comma-separated Google Workspace domains, e.g. virgo.hu,example.hu */
export function googleHostedDomains() {
  return [...new Set((process.env.GOOGLE_HOSTED_DOMAIN ?? "")
    .split(",")
    .map((domain) => domain.trim().toLowerCase())
    .filter(Boolean))];
}

export function appOrigin(requestUrl: string) {
  const configured = process.env.APP_ORIGIN?.trim().replace(/\/$/, "");
  if (configured) return configured;
  return new URL(requestUrl).origin;
}

export function googleCallbackUrl(requestUrl: string) {
  return `${appOrigin(requestUrl)}/api/auth/google/callback`;
}
