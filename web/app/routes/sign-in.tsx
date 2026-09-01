import { ArrowRight, Eye, LoaderCircle } from "lucide-react";
import { useState } from "react";
import { useNavigate } from "react-router";
import { beginSignIn, startPreviewSession } from "~/lib/auth.client";
import { buddyConfig } from "~/lib/config";

export function meta() {
  return [
    { title: "Buddy — KAIST, together" },
    {
      name: "description",
      content: "Sign in to Buddy, the campus feed for the KAIST community.",
    },
  ];
}

export default function SignIn() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = async () => {
    setLoading(true);
    setError(null);
    try {
      await beginSignIn();
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "SPARCS SSO could not be opened.");
      setLoading(false);
    }
  };

  const preview = () => {
    startPreviewSession();
    navigate("/feed");
  };

  return (
    <main className="sign-in-page">
      <section className="sign-in-story" aria-label="About Buddy">
        <div className="story-content">
          <div className="brand-lockup">
            <img src="/buddy-logo-dark.png" alt="" />
            <span>Buddy</span>
          </div>
          <p className="eyebrow">MADE FOR KAIST</p>
          <h1>Your campus,<br />in one conversation.</h1>
          <p className="story-copy">
            See what the community is talking about, share a thought, and stay close to campus life.
          </p>
        </div>
        <p className="story-footnote">A SPARCS service for the KAIST community.</p>
      </section>

      <section className="sign-in-panel">
        <div className="sign-in-card">
          <img className="sign-in-logo" src="/buddy-logo-light.png" alt="Buddy" />
          <div className="sign-in-heading">
            <p className="eyebrow">WELCOME TO BUDDY</p>
            <h2>Join the conversation.</h2>
            <p>Use your SPARCS account to continue to the campus feed.</p>
          </div>

          <button className="sso-button" type="button" onClick={signIn} disabled={loading}>
            <span>{loading ? "Opening SPARCS SSO…" : "Continue with SPARCS SSO"}</span>
            {loading ? <LoaderCircle className="spinning" aria-hidden="true" size={19} /> : <ArrowRight aria-hidden="true" size={19} strokeWidth={2.2} />}
          </button>

          {buddyConfig.previewEnabled && (
            <button className="preview-button" type="button" onClick={preview}>
              <Eye aria-hidden="true" size={18} />
              View a preview
            </button>
          )}

          {error && <p className="sign-in-error" role="alert">{error}</p>}

          <p className="terms-copy">
            By continuing, you agree to our{" "}
            <a href="https://github.com/sparcs-kaist/privacy/blob/main/TermsOfUse.md">Terms of Use</a>{" "}
            and{" "}
            <a href="https://github.com/sparcs-kaist/privacy/blob/main/Privacy.md">Privacy Policy</a>.
          </p>

          <div className="sponsor-lockup">
            <span>Sponsored by</span>
            <img src="/hyundai-mobis-light.png" alt="Hyundai Mobis" />
          </div>
        </div>
      </section>
    </main>
  );
}
