// Live store / test-track install links.
// Android open testing is public. iOS still requires an invitation by email.
export const STORE_LINKS = {
  // TestFlight link. Apple opens it only for Apple IDs that are already on the
  // tester list in App Store Connect, so the site never hands it out: it goes
  // into the invitation email we send after adding the applicant as a tester.
  ios: "https://testflight.apple.com/join/sbvJNQSt",
  // Public opt-in page; Google Play presents the install link after joining.
  android: "https://play.google.com/apps/testing/com.sujinarin.ko_lernen_app",
} as const;
