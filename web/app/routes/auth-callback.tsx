import { LoaderCircle } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router";
import { completeSignIn } from "~/lib/auth.client";

export function meta() {
  return [{ title: "Signing in — Buddy" }];
}

export default function AuthCallback() {
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const session = params.get("session");
    if (!session) {
      setError("SPARCS SSO did not return a session. Please try again.");
      return;
    }
    completeSignIn(session)
      .then(() => navigate("/feed", { replace: true }))
      .catch((reason: unknown) => {
        setError(reason instanceof Error ? reason.message : "Sign-in could not be completed.");
      });
  }, [navigate]);

  return (
    <main className="callback-page">
      <img src="/buddy-logo-light.png" alt="Buddy" />
      {error ? (
        <>
          <h1>We couldn’t sign you in.</h1>
          <p>{error}</p>
          <Link to="/">Back to sign in</Link>
        </>
      ) : (
        <>
          <LoaderCircle className="callback-spinner" aria-hidden="true" />
          <h1>Opening your feed…</h1>
          <p>Buddy is finishing your SPARCS sign-in.</p>
        </>
      )}
    </main>
  );
}
