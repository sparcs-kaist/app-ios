import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("routes/sign-in.tsx"),
  route("auth/callback", "routes/auth-callback.tsx"),
  route("feed", "routes/feed.tsx"),
] satisfies RouteConfig;
