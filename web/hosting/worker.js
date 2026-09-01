export default {
  async fetch() {
    return new globalThis.Response("Not Found", { status: 404 });
  },
};
