import com.android.aapt.Resources;
import com.android.bundle.Commands;
import com.android.tools.build.bundletool.model.AndroidManifest;
import com.android.tools.build.bundletool.model.ModuleDeliveryType;
import com.android.tools.build.bundletool.model.utils.ApkSizeUtils;
import com.android.tools.build.bundletool.model.utils.ResultUtils;
import com.google.common.collect.ImmutableList;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipInputStream;

/** Read-only verification and the exact pinned bundletool per-APK size API. */
public final class AndroidArtworkDownloadSize {
  private static final String MODULE = "c_artwork";
  private static final String ART = "assets/illustrations/ildu_r16/";
  private static final String APK_PREFIX = "assets/flutter_assets/";
  private static final String AAB_PREFIX = MODULE + "/assets/flutter_assets/";
  private static final int EXPECTED_ASSETS = 135;
  // AGP 9.0.1 emits this 748-byte resource marker even without feature code.
  // Reviewed: exact R class, no fields/interfaces, private ()V constructor
  // invokes Object.<init> once and returns. Never auto-update this identity.
  private static final String REVIEWED_RESOURCE_DEX =
      "89093ecf4efd0f3f3ef56065147c3c911d11a2b9a62488c60e237d3c6f14fdbb";

  private static void require(boolean test, String message) {
    if (!test) { throw new IllegalStateException(message); }
  }
  private static String q(String value) {
    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"")
        .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t") + "\"";
  }
  private record EntryDigest(String sha256, long bytes) {}
  private static EntryDigest digestEntry(InputStream input) throws Exception {
    MessageDigest sha = MessageDigest.getInstance("SHA-256");
    byte[] buffer = new byte[65536];
    int count;
    long bytes = 0;
    while ((count = input.read(buffer)) != -1) {
      sha.update(buffer, 0, count);
      bytes += count;
    }
    StringBuilder result = new StringBuilder();
    for (byte b : sha.digest()) { result.append(String.format("%02x", b & 255)); }
    return new EntryDigest(result.toString(), bytes);
  }
  private static String digest(InputStream input) throws Exception {
    return digestEntry(input).sha256();
  }
  private static String fileDigest(Path file) throws Exception {
    try (InputStream input = Files.newInputStream(file)) { return digest(input); }
  }
  private static AndroidManifest manifest(ZipFile bundle, String module) throws Exception {
    ZipEntry entry = bundle.getEntry(module + "/manifest/AndroidManifest.xml");
    require(entry != null, "Missing compiled manifest: " + module);
    try (InputStream input = bundle.getInputStream(entry)) {
      return AndroidManifest.create(Resources.XmlNode.parseFrom(input));
    }
  }
  private static Map<String, String> aabArtwork(ZipFile bundle) throws Exception {
    Map<String, String> expected = new TreeMap<>();
    Enumeration<? extends ZipEntry> entries = bundle.entries();
    while (entries.hasMoreElements()) {
      ZipEntry entry = entries.nextElement();
      if (entry.isDirectory()) { continue; }
      String name = entry.getName();
      if (name.contains("/assets/flutter_assets/" + ART)) {
        require(name.startsWith(AAB_PREFIX + ART), "Artwork outside its module: " + name);
        String key = name.substring(AAB_PREFIX.length());
        require(key.endsWith(".webp"), "Unexpected artwork payload: " + name);
        try (InputStream input = bundle.getInputStream(entry)) {
          require(expected.put(key, digest(input)) == null, "Duplicate AAB artwork: " + key);
        }
      }
    }
    require(expected.size() == EXPECTED_ASSETS, "AAB must have exactly135 artwork payloads");
    ZipEntry index = bundle.getEntry("base/assets/flutter_assets/AssetManifest.bin");
    require(index != null && index.getSize() > 0, "Base Flutter AssetManifest is missing/empty");
    return expected;
  }
  private static List<String> verifyMaster(ZipFile apks, String path,
      Map<String, String> expected) throws Exception {
    ZipEntry entry = apks.getEntry(path);
    require(entry != null, "Missing APK selected by TOC: " + path);
    Map<String, String> actual = new TreeMap<>();
    List<String> codeEntries = new ArrayList<>();
    try (ZipInputStream apk = new ZipInputStream(apks.getInputStream(entry))) {
      ZipEntry payload;
      while ((payload = apk.getNextEntry()) != null) {
        String name = payload.getName();
        if (name.endsWith(".dex") || name.startsWith("lib/")) {
          codeEntries.add(name);
          require(name.equals("classes.dex"), "Artwork contains unexpected application code: " + name);
          EntryDigest marker = digestEntry(apk);
          require(marker.sha256().equals(REVIEWED_RESOURCE_DEX) && marker.bytes() == 748
              && payload.getSize() == 748,
              "Artwork resource marker differs from reviewed pin: " + name
                  + " actualBytes=" + marker.bytes() + " zipBytes=" + payload.getSize()
                  + " sha256=" + marker.sha256());
        }
        if (name.startsWith(APK_PREFIX + ART) && !payload.isDirectory()) {
          String key = name.substring(APK_PREFIX.length());
          require(actual.put(key, digest(apk)) == null, "Duplicate APK artwork: " + key);
        }
      }
    }
    require(actual.equals(expected), "APK master does not contain the exact135 AAB payloads: " + path);
    return codeEntries;
  }

  public static void main(String[] args) throws Exception {
    require(args.length == 2, "Usage: AndroidArtworkDownloadSize.java <AAB> <APKS>");
    Path aab = Path.of(args[0]);
    Path apksPath = Path.of(args[1]);
    Map<String, String> expected;
    int baseSdk;
    int moduleSdk;
    try (ZipFile bundle = new ZipFile(aab.toFile())) {
      AndroidManifest base = manifest(bundle, "base");
      AndroidManifest module = manifest(bundle, MODULE);
      baseSdk = base.getEffectiveMinSdkVersion();
      moduleSdk = module.getEffectiveMinSdkVersion();
      require(baseSdk == 24 && moduleSdk == baseSdk, "Base/artwork minSdk must both be24");
      require(!base.getIsolatedSplits().orElse(false), "Base isolated splits need a different asset-access proof");
      require(!module.getEffectiveHasCode(), "Artwork module must have hasCode=false");
      require(module.getIsModuleIncludedInFusing().orElse(false), "Artwork fusing must remain true");
      require(module.getModuleDeliveryType() == ModuleDeliveryType.ALWAYS_INITIAL_INSTALL,
          "Artwork must be unconditionally install-time");
      expected = aabArtwork(bundle);
    }

    Commands.BuildApksResult toc = ResultUtils.readTableOfContents(apksPath);
    require(toc.getVariantCount() > 0, "APK set has no variants");
    Map<String, Integer> masters = new TreeMap<>();
    List<String> variants = new ArrayList<>();
    for (Commands.Variant variant : toc.getVariantList()) {
      int moduleSets = 0;
      int baseSets = 0;
      String master = null;
      for (Commands.ApkSet set : variant.getApkSetList()) {
        for (Commands.ApkDescription apk : set.getApkDescriptionList()) {
          require(apk.hasSplitApkMetadata(),
              "Standalone/universal/instant/system APK variant is not supported by this bound: " + apk.getPath());
        }
        if (set.getModuleMetadata().getName().equals("base")) { baseSets++; }
        if (!set.getModuleMetadata().getName().equals(MODULE)) { continue; }
        moduleSets++;
        require(set.getApkDescriptionCount() == 1, "Artwork module must contain only its reviewed master");
        Commands.ModuleMetadata meta = set.getModuleMetadata();
        require(meta.getDeliveryType().name().equals("INSTALL_TIME")
            && !meta.getIsInstant()
            && meta.getTargeting().getSerializedSize() == 0,
            "Every variant must include unconditional install-time artwork: " + variant.getVariantNumber());
        List<Commands.ApkDescription> selected = new ArrayList<>();
        for (Commands.ApkDescription apk : set.getApkDescriptionList()) {
          if (apk.getSplitApkMetadata().getIsMasterSplit()) { selected.add(apk); }
        }
        require(selected.size() == 1, "Every variant must have exactlyone artwork master");
        Commands.ApkDescription apk = selected.get(0);
        require(apk.getTargeting().toBuilder().clearSdkVersionTargeting().build()
            .getSerializedSize() == 0, "Artwork master has non-SDK device conditions");
        var variantSdk = variant.getTargeting().getSdkVersionTargeting();
        require(variantSdk.getValueCount() == 1, "Variant needs one SDK lower bound");
        int variantMinSdk = variantSdk.getValue(0).getMin().getValue();
        var masterSdk = apk.getTargeting().getSdkVersionTargeting();
        require(masterSdk.getAlternativesCount() == 0 && masterSdk.getValueCount() <= 1,
            "Artwork master has unsupported SDK alternatives");
        int masterMinSdk = masterSdk.getValueCount() == 0 ? 1
            : masterSdk.getValue(0).getMin().getValue();
        require(masterMinSdk <= Math.max(baseSdk, variantMinSdk),
            "Artwork master omits compatible SDKs in its variant");
        master = apk.getPath();
        masters.put(master, EXPECTED_ASSETS);
      }
      require(baseSets == 1 && moduleSets == 1, "Every variant must have one base and one artwork module");
      variants.add("{\"variant\":" + variant.getVariantNumber()
          + ",\"targeting\":" + q(variant.getTargeting().toString())
          + ",\"master\":" + q(master) + "}");
    }

    List<String> masterRows = new ArrayList<>();
    long lowerBound = Long.MAX_VALUE;
    boolean noPackagedCode = true;
    Map<String, Long> vendor = ApkSizeUtils.getCompressedSizeByApkPaths(
        ImmutableList.copyOf(masters.keySet()), apksPath);
    try (ZipFile apks = new ZipFile(apksPath.toFile())) {
      for (String master : masters.keySet()) {
        List<String> codeEntries = verifyMaster(apks, master, expected);
        noPackagedCode &= codeEntries.isEmpty();
        long raw = apks.getEntry(master).getSize();
        long size = vendor.get(master);
        require(size > 0 && size <= raw, "Invalid vendor compressed size: " + master);
        lowerBound = Math.min(lowerBound, size);
        masterRows.add("{\"path\":" + q(master) + ",\"assetCount\":" + EXPECTED_ASSETS
            + ",\"rawApkBytes\":" + raw + ",\"vendorDownloadBytes\":" + size
            + ",\"codeEntries\":[" + codeEntries.stream().map(AndroidArtworkDownloadSize::q)
                .collect(java.util.stream.Collectors.joining(",")) + "]}");
      }
    }
    System.out.println("{\"schemaVersion\":1,\"measurementMethod\":"
        + q("bundletool ApkSizeUtils.getCompressedSizeByApkPaths; min(raw APK bytes, vendor GZIP bytes)")
        + ",\"aabSha256\":" + q(fileDigest(aab)) + ",\"apksSha256\":" + q(fileDigest(apksPath))
        + ",\"module\":" + q(MODULE) + ",\"baseMinSdk\":" + baseSdk
        + ",\"artworkMinSdk\":" + moduleSdk + ",\"variantCount\":" + toc.getVariantCount()
        + ",\"assetCount\":" + EXPECTED_ASSETS + ",\"noPackagedDexOrNativeCode\":" + noPackagedCode
        + ",\"noPackagedApplicationCode\":true"
        + ",\"moduleLowerBoundBytes\":" + lowerBound
        + ",\"variants\":[" + String.join(",", variants) + "]"
        + ",\"masters\":[" + String.join(",", masterRows) + "]}");
  }
}
