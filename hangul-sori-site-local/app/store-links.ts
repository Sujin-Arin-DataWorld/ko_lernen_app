// Live store / test-track install links.
// Gate model: these are revealed only AFTER a visitor submits the tester form,
// so every install still leaves a name + email in our list.
export const STORE_LINKS = {
  // Public TestFlight link — anyone with the link can install immediately.
  ios: "https://testflight.apple.com/join/sbvJNQSt",
  // Google Play listing / test track for the app.
  android: "https://play.google.com/store/apps/details?id=com.sujinarin.ko_lernen_app",
} as const;
