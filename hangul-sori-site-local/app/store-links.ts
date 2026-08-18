// Live store / test-track install links.
// Gate model: these are revealed only AFTER a visitor submits the tester form,
// so every install still leaves a name + email in our list.
export const STORE_LINKS = {
  // TestFlight link. Apple opens it only for Apple IDs that are already on the
  // tester list in App Store Connect, so the site never hands it out: it goes
  // into the invitation email we send after adding the applicant as a tester.
  ios: "https://testflight.apple.com/join/sbvJNQSt",
  // Google Play listing / test track for the app.
  android: "https://play.google.com/store/apps/details?id=com.sujinarin.ko_lernen_app",
} as const;
