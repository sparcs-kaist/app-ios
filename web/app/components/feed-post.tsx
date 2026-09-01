import { BadgeCheck, ChevronDown, ChevronUp, MessageCircle, MoreHorizontal } from "lucide-react";
import { useState } from "react";
import type { FeedPost as FeedPostType } from "~/types/feed";

type Props = {
  post: FeedPostType;
  onVote: (postID: string, vote: "UP" | "DOWN") => void;
  voting: boolean;
};

function Avatar({ post }: { post: FeedPostType }) {
  if (post.profileImageURL) {
    return <img className="post-avatar" src={post.profileImageURL} alt="" loading="lazy" />;
  }
  return (
    <span className={`post-avatar avatar-fallback ${post.isAnonymous ? "anonymous" : ""}`} aria-hidden="true">
      {post.isAnonymous ? "?" : post.authorName.slice(0, 1).toUpperCase()}
    </span>
  );
}

export function FeedPost({ post, onVote, voting }: Props) {
  const [expanded, setExpanded] = useState(false);
  const [revealedSpoilers, setRevealedSpoilers] = useState<Set<string>>(() => new Set());
  const longPost = post.content.length > 320 || post.content.split("\n").length > 5;

  return (
    <article className="feed-post">
      <div className="post-avatar-column">
        <Avatar post={post} />
        <span className="thread-line" aria-hidden="true" />
      </div>

      <div className="post-main">
        <header className="post-header">
          <div className="post-identity">
            <strong>{post.authorName}</strong>
            {post.isKaistIP && (
              <BadgeCheck className="verified-icon" size={16} fill="currentColor" aria-label="Posted from the KAIST network" />
            )}
            <time dateTime={post.createdAt}>{post.timeText}</time>
          </div>
          <button className="icon-button post-more" type="button" aria-label="More options" title="More options">
            <MoreHorizontal size={19} />
          </button>
        </header>

        <div className={`post-copy ${longPost && !expanded ? "collapsed" : ""}`}>{post.content}</div>
        {longPost && !expanded && (
          <button className="text-button" type="button" onClick={() => setExpanded(true)}>more</button>
        )}

        {post.images.length > 0 && (
          <div className={`post-images count-${Math.min(post.images.length, 3)}`}>
            {post.images.map((image) => {
              const hidden = image.spoiler && !revealedSpoilers.has(image.id);
              return (
                <div className="post-image-frame" key={image.id}>
                  <a href={image.url} target="_blank" rel="noreferrer" aria-label="Open image">
                    <img src={image.url} alt="Post attachment" loading="lazy" />
                  </a>
                  {hidden && (
                    <button
                      className="spoiler-cover"
                      type="button"
                      onClick={() => setRevealedSpoilers((current) => new Set(current).add(image.id))}
                    >
                      <span>Spoiler</span>
                      <small>Tap to reveal</small>
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <footer className="post-actions">
          <div className="vote-control" aria-label={`${post.score} net votes`}>
            <button
              className={post.myVote === "UP" ? "active up" : ""}
              type="button"
              aria-label="Upvote"
              aria-pressed={post.myVote === "UP"}
              disabled={voting}
              onClick={() => onVote(post.id, "UP")}
            >
              <ChevronUp size={18} strokeWidth={2.3} />
            </button>
            <span>{post.score}</span>
            <button
              className={post.myVote === "DOWN" ? "active down" : ""}
              type="button"
              aria-label="Downvote"
              aria-pressed={post.myVote === "DOWN"}
              disabled={voting}
              onClick={() => onVote(post.id, "DOWN")}
            >
              <ChevronDown size={18} strokeWidth={2.3} />
            </button>
          </div>
          <span className="comment-count" aria-label={`${post.commentCount} comments`}>
            <MessageCircle size={17} />
            {post.commentCount}
          </span>
        </footer>
      </div>
    </article>
  );
}
