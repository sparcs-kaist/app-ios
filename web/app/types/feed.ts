export type FeedImage = {
  id: string;
  url: string;
  mimeType: string;
  spoiler: boolean;
};

export type FeedPost = {
  id: string;
  content: string;
  authorName: string;
  profileImageURL: string | null;
  createdAt: string;
  timeText: string;
  isAnonymous: boolean;
  isKaistIP: boolean;
  commentCount: number;
  upvotes: number;
  downvotes: number;
  score: number;
  myVote: "UP" | "DOWN" | null;
  isAuthor: boolean;
  images: FeedImage[];
};

export type FeedViewModelState = {
  phase: "loading" | "loaded" | "error";
  posts: FeedPost[];
  nextCursor: string | null;
  hasNext: boolean;
  isRefreshing: boolean;
  isLoadingMore: boolean;
  votingPostIDs: string[];
  errorMessage: string | null;
  notice: string | null;
};

export type FeedPageIntent = "initial" | "refresh" | "next";

export type PageActionResult = {
  state: FeedViewModelState;
  request: {
    intent: FeedPageIntent;
    url: string;
  } | null;
};

export type VoteBridgeResult = {
  state: FeedViewModelState;
  method: "POST" | "DELETE";
  vote: "UP" | "DOWN" | null;
  path: string;
};
