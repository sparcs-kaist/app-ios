import { Home, LoaderCircle, LogOut, Sparkles } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router";
import { FeedPost } from "~/components/feed-post";
import { getFeedEngine } from "~/features/feed/feed-engine.client";
import { authorizedFetch, getSession, signOut } from "~/lib/auth.client";
import { browserLanguage } from "~/lib/browser.client";
import { buddyConfig } from "~/lib/config";
import type {
  FeedPageIntent,
  FeedViewModelState,
  PageActionResult,
  VoteBridgeResult,
} from "~/types/feed";

export function meta() {
  return [
    { title: "Feed — Buddy" },
    { name: "description", content: "The KAIST community feed on Buddy." },
  ];
}

function FeedSkeleton() {
  return (
    <div className="feed-skeleton" aria-label="Loading feed">
      {[0, 1, 2].map((item) => (
        <div className="skeleton-post" key={item}>
          <span className="skeleton-avatar" />
          <div><span className="skeleton-line short" /><span className="skeleton-line" /><span className="skeleton-line medium" /></div>
        </div>
      ))}
    </div>
  );
}

function failureMessage(intent: FeedPageIntent) {
  if (intent === "refresh") return "Buddy couldn’t refresh the feed.";
  if (intent === "next") return "More posts couldn’t be loaded.";
  return "Buddy couldn’t load the feed right now.";
}

export default function Feed() {
  const navigate = useNavigate();
  const [state, setState] = useState<FeedViewModelState | null>(null);
  const loadMoreRef = useRef<HTMLDivElement>(null);
  const sessionMode = typeof window === "undefined" ? null : getSession()?.mode ?? null;

  const loadFeed = useCallback(async (intent: FeedPageIntent) => {
    const currentSession = getSession();
    if (!currentSession) {
      navigate("/", { replace: true });
      return;
    }

    const engine = await getFeedEngine();
    const language = browserLanguage();
    if (currentSession.mode === "preview") {
      setState(JSON.parse(engine.loadPreview(language)) as FeedViewModelState);
      return;
    }

    const encodedAction = intent === "initial"
      ? engine.beginInitialLoad(buddyConfig.feedBaseURL, language)
      : intent === "refresh"
        ? engine.beginRefresh(buddyConfig.feedBaseURL, language)
        : engine.beginNextPage(buddyConfig.feedBaseURL, language);
    const action = JSON.parse(encodedAction) as PageActionResult;
    setState(action.state);
    if (!action.request) return;

    try {
      const response = await authorizedFetch(action.request.url);
      if (!response.ok) throw new Error(failureMessage(intent));
      setState(JSON.parse(
        engine.receivePage(await response.text(), action.request.intent, language),
      ) as FeedViewModelState);
    } catch (reason) {
      const message = reason instanceof Error ? reason.message : failureMessage(intent);
      setState(JSON.parse(
        engine.failPage(action.request.intent, message, language),
      ) as FeedViewModelState);
    }
  }, [navigate]);

  useEffect(() => {
    if (!sessionMode) {
      navigate("/", { replace: true });
      return;
    }
    void loadFeed("initial");
  }, [loadFeed, navigate, sessionMode]);

  const loadMore = useCallback(async () => {
    if (!state?.hasNext || state.isLoadingMore) return;
    await loadFeed("next");
  }, [loadFeed, state?.hasNext, state?.isLoadingMore]);

  useEffect(() => {
    const target = loadMoreRef.current;
    if (!target || !state?.hasNext) return;
    const observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) void loadMore();
    }, { rootMargin: "240px" });
    observer.observe(target);
    return () => observer.disconnect();
  }, [loadMore, state?.hasNext]);

  const vote = async (postID: string, voteType: "UP" | "DOWN") => {
    const engine = await getFeedEngine();
    const language = browserLanguage();
    const result = JSON.parse(engine.toggleVote(postID, voteType, language)) as VoteBridgeResult;
    setState(result.state);

    try {
      if (getSession()?.mode === "live") {
        const response = await authorizedFetch(`${buddyConfig.feedBaseURL}${result.path}`, {
          method: result.method,
          headers: result.vote ? { "Content-Type": "application/json" } : undefined,
          body: result.vote ? JSON.stringify({ vote: result.vote }) : undefined,
        });
        if (!response.ok) throw new Error("Your vote couldn’t be saved.");
      }
      setState(JSON.parse(engine.commitVote(postID, language)) as FeedViewModelState);
    } catch (reason) {
      const message = reason instanceof Error ? reason.message : "Your vote couldn’t be saved.";
      setState(JSON.parse(engine.failVote(postID, message, language)) as FeedViewModelState);
    }
  };

  const dismissNotice = async () => {
    const engine = await getFeedEngine();
    setState(JSON.parse(engine.dismissNotice(browserLanguage())) as FeedViewModelState);
  };

  const leave = () => {
    signOut();
    navigate("/", { replace: true });
  };

  const error = state?.phase === "error" ? state.errorMessage : null;
  return (
    <div className="app-shell">
      <aside className="left-rail">
        <div>
          <a className="rail-brand" href="/feed" aria-label="Buddy feed">
            <img src="/buddy-logo-light.png" alt="" />
            <span>Buddy</span>
          </a>
          <nav className="rail-nav" aria-label="Main navigation">
            <a className="active" href="/feed"><Home size={21} fill="currentColor" /><span>Feed</span></a>
          </nav>
        </div>
        <button className="rail-signout" type="button" onClick={leave}><LogOut size={19} /><span>Sign out</span></button>
      </aside>

      <main className="feed-column">
        <header className="feed-header">
          <div className="mobile-brand"><img src="/buddy-logo-light.png" alt="" /><span>Buddy</span></div>
          <div><h1>Feed</h1></div>
        </header>

        {sessionMode === "preview" && (
          <div className="preview-banner"><Sparkles size={17} /><span>You’re exploring a preview of Buddy.</span></div>
        )}

        {error ? (
          <section className="feed-error">
            <h2>The feed is taking a break.</h2><p>{error}</p><button type="button" onClick={() => void loadFeed("initial")}>Try again</button>
          </section>
        ) : state?.phase === "loaded" ? (
          state.posts.length ? (
            <div className="feed-list">
              {state.posts.map((post) => (
                <FeedPost key={post.id} post={post} onVote={vote} voting={state.votingPostIDs.includes(post.id)} />
              ))}
              <div className="load-more-marker" ref={loadMoreRef}>
                {state.isLoadingMore && <><LoaderCircle className="spinning" size={18} /><span>Loading more</span></>}
              </div>
            </div>
          ) : (
            <section className="empty-feed"><Sparkles size={25} /><h2>Quiet for now.</h2><p>The next campus conversation will appear here.</p></section>
          )
        ) : <FeedSkeleton />}
      </main>

      <nav className="mobile-nav" aria-label="Mobile navigation">
        <a className="active" href="/feed"><Home size={21} fill="currentColor" /><span>Feed</span></a>
        <button type="button" onClick={leave}><LogOut size={21} /><span>Sign out</span></button>
      </nav>

      {state?.notice && (
        <div className="toast" role="status"><span>{state.notice}</span><button type="button" onClick={() => void dismissNotice()}>Dismiss</button></div>
      )}
    </div>
  );
}
