import { reactRouter } from "@react-router/dev/vite";
import { sites } from "@openai/sites-vite-plugin";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [tailwindcss(), sites(), reactRouter()],
  resolve: { tsconfigPaths: true },
  server: {
    watch: {
      ignored: ["**/swift/.build/checkouts/**", "**/swift/.build/repositories/**"],
    },
  },
});
