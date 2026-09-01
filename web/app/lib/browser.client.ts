export function browserLanguage() {
  return typeof navigator === "undefined" ? "en" : navigator.language;
}
