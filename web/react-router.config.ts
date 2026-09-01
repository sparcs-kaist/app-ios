import type { Config } from "@react-router/dev/config";

export default {
  ssr: false,
  basename: process.env.VITE_BASE_PATH || "/",
} satisfies Config;
