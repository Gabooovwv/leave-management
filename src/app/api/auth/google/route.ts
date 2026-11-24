import { randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import {
  appOrigin,
  googleAuthConfigured,
  googleCallbackUrl,
  googleClientId,
  googleHostedDomains,
} from "@/lib/google-auth";

async function startGoogleLogin(request: Request) {
  const origin = appOrigin(request.url);
  if (!googleAuthConfigured()) {
    return NextResponse.redirect(new URL("/login?error=google_config", origin));
  }

  const state = randomBytes(16).toString("base64url");
  const jar = await cookies();
  jar.set("virgo_google_state", state, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 10,
  });

  const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  url.searchParams.set("client_id", googleClientId());
  url.searchParams.set("redirect_uri", googleCallbackUrl(request.url));
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid email profile");
  url.searchParams.set("state", state);
  url.searchParams.set("prompt", "select_account");
  url.searchParams.set("access_type", "online");

  const hostedDomains = googleHostedDomains();
  if (hostedDomains.length > 0) {
    // Google accepts one domain or "*" as a UI hint; enforce the list in the callback.
    url.searchParams.set("hd", hostedDomains.length === 1 ? hostedDomains[0] : "*");
  }

  return NextResponse.redirect(url);
}

export async function GET(request: Request) {
  return startGoogleLogin(request);
}

export async function POST(request: Request) {
  return startGoogleLogin(request);
}
