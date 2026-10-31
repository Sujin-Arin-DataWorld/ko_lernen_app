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
  private static final String APK_PREFIX = "assets/flutter_assets/";
  private static final String AAB_PREFIX = MODULE + "/assets/flutter_assets/";
  // Baseline and CI8066 have the same empty R class and compiler metadata.
  // Only the 64-lower-hex R8 pg-map-id and its dependent DEX headers may vary.
  // Validate headers first; pin every remaining byte. Never auto-update this identity.
  private static final String REVIEWED_RESOURCE_DEX_CANONICAL_SHA256 =
      "3263949d258208c751773f89d25801463dba621517c8c3ce2a130b91c9df3f6b";

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
  private record ArtworkManifest(Map<String, EntryDigest> assets, Map<String, Integer> groups) {}
  private static boolean safePath(String value) {
    return !value.isEmpty() && value.chars().noneMatch(c -> "\\:*?[]<>\"|".indexOf(c) >= 0 || c < 32 || c == 127)
        && java.util.Arrays.stream(value.split("/", -1)).noneMatch(p -> p.isEmpty() || p.equals(".") || p.equals(".."));
  }
  private static ArtworkManifest artworkManifest(Path path) throws Exception {
    List<String> lines = Files.readAllLines(path);
    require(!lines.isEmpty() && lines.get(0).equals("# c-artwork-manifest-v1"), "Unsupported artwork manifest");
    Map<String, String> roots = new TreeMap<>();
    Map<String, Integer> groups = new TreeMap<>();
    int row = 1;
    while (row < lines.size() && lines.get(row).startsWith("# authority\t")) {
      String[] f = lines.get(row++).split("\t", -1);
      require(f.length == 6, "Invalid artwork authority");
      require(f[1].matches("[a-z0-9-]+") && safePath(f[2]) && f[3].matches("[0-9a-f]{64}")
          && f[4].startsWith("assets/") && f[4].endsWith("/")
          && safePath(f[4].substring(0, f[4].length() - 1)), "Unsafe artwork authority");
      require(roots.put(f[1], f[4]) == null && Integer.parseInt(f[5]) > 0, "Duplicate/empty artwork authority");
      groups.put(f[1], Integer.parseInt(f[5]));
    }
    require(!groups.isEmpty() && row < lines.size() && lines.get(row++).equals("asset\tsha256\tbytes\tgroup"),
        "Missing artwork manifest columns");
    Map<String, EntryDigest> assets = new TreeMap<>();
    Map<String, Integer> actualGroups = new TreeMap<>();
    String previous = "";
    for (; row < lines.size(); row++) {
      String[] f = lines.get(row).split("\t", -1);
      require(f.length == 4, "Invalid artwork manifest row");
      require(safePath(f[0]) && f[1].matches("[0-9a-f]{64}") && Long.parseLong(f[2]) > 0
          && roots.containsKey(f[3]) && f[0].startsWith(roots.get(f[3]))
          && f[0].compareTo(previous) > 0, "Unsafe/unsorted artwork identity");
      require(assets.put(f[0], new EntryDigest(f[1], Long.parseLong(f[2]))) == null, "Duplicate artwork identity");
      actualGroups.merge(f[3], 1, Integer::sum);
      previous = f[0];
    }
    require(actualGroups.equals(groups), "Artwork manifest group count differs");
    return new ArtworkManifest(assets, groups);
  }
  private static void aabArtwork(ZipFile bundle, Map<String, EntryDigest> expected) throws Exception {
    Map<String, EntryDigest> actual = new TreeMap<>();
    Enumeration<? extends ZipEntry> entries = bundle.entries();
    while (entries.hasMoreElements()) {
      ZipEntry entry = entries.nextElement();
      if (entry.isDirectory()) { continue; }
      String name = entry.getName();
      int flutter = name.indexOf("/assets/flutter_assets/");
      if (flutter >= 0 && expected.containsKey(name.substring(flutter + "/assets/flutter_assets/".length()))) {
        require(name.startsWith(AAB_PREFIX), "Artwork outside its module: " + name);
      }
      if (name.startsWith(AAB_PREFIX)) {
        String key = name.substring(AAB_PREFIX.length());
        try (InputStream input = bundle.getInputStream(entry)) {
          require(actual.put(key, digestEntry(input)) == null, "Duplicate AAB artwork: " + key);
        }
      }
    }
    require(actual.equals(expected), "AAB artwork differs from the exact manifest payloads");
    ZipEntry index = bundle.getEntry("base/assets/flutter_assets/AssetManifest.bin");
    require(index != null && index.getSize() > 0, "Base Flutter AssetManifest is missing/empty");
  }
  private static boolean isReviewedResourceMarker(byte[] marker) throws Exception {
    if (marker.length != 748) { return false; }
    java.util.zip.Adler32 checksum = new java.util.zip.Adler32();
    checksum.update(marker, 12, marker.length - 12);
    long declaredChecksum = 0;
    for (int i = 0; i < 4; i++) { declaredChecksum |= (marker[8 + i] & 255L) << (8 * i); }
    if (checksum.getValue() != declaredChecksum) { return false; }
    byte[] signature = MessageDigest.getInstance("SHA-1").digest(
        java.util.Arrays.copyOfRange(marker, 32, marker.length));
    if (!MessageDigest.isEqual(signature, java.util.Arrays.copyOfRange(marker, 12, 32))) {
      return false;
    }
    String bytesAsText = new String(marker, java.nio.charset.StandardCharsets.ISO_8859_1);
    String field = "\"pg-map-id\":\"";
    if (bytesAsText.indexOf(field) != 496 || bytesAsText.lastIndexOf(field) != 496
        || marker[573] != '"') { return false; }
    for (int i = 509; i < 573; i++) {
      int value = marker[i] & 255;
      if (!((value >= '0' && value <= '9') || (value >= 'a' && value <= 'f'))) { return false; }
    }
    byte[] canonical = marker.clone();
    java.util.Arrays.fill(canonical, 8, 32, (byte) 0);
    java.util.Arrays.fill(canonical, 509, 573, (byte) '0');
    return digest(new java.io.ByteArrayInputStream(canonical))
        .equals(REVIEWED_RESOURCE_DEX_CANONICAL_SHA256);
  }

  private static List<String> verifyMaster(ZipFile apks, String path,
      Map<String, EntryDigest> expected) throws Exception {
    ZipEntry entry = apks.getEntry(path);
    require(entry != null, "Missing APK selected by TOC: " + path);
    Map<String, EntryDigest> actual = new TreeMap<>();
    List<String> codeEntries = new ArrayList<>();
    try (ZipInputStream apk = new ZipInputStream(apks.getInputStream(entry))) {
      ZipEntry payload;
      while ((payload = apk.getNextEntry()) != null) {
        String name = payload.getName();
        if (name.endsWith(".dex") || name.startsWith("lib/")) {
          require(!codeEntries.contains(name), "Duplicate artwork code entry: " + name);
          codeEntries.add(name);
          require(name.equals("classes.dex"), "Artwork contains unexpected application code: " + name);
          // Bound retained bytes while still counting an oversized entry to EOF.
          byte[] markerBytes = apk.readNBytes(749);
          if (markerBytes.length != 748) {
            long actualBytes = markerBytes.length + digestEntry(apk).bytes();
            throw new IllegalStateException("Artwork resource marker has unexpected size: " + name
                + " actualBytes=" + actualBytes + " zipBytes=" + payload.getSize());
          }
          EntryDigest marker = digestEntry(new java.io.ByteArrayInputStream(markerBytes));
          require(isReviewedResourceMarker(markerBytes) && marker.bytes() == 748
              && payload.getSize() == 748,
              "Artwork resource marker differs from reviewed canonical bytes: " + name
                  + " actualBytes=" + marker.bytes() + " zipBytes=" + payload.getSize()
                  + " sha256=" + marker.sha256());
        }
        if (name.startsWith(APK_PREFIX) && !payload.isDirectory()) {
          String key = name.substring(APK_PREFIX.length());
          require(actual.put(key, digestEntry(apk)) == null, "Duplicate APK artwork: " + key);
        }
      }
    }
    require(actual.equals(expected), "APK master differs from the exact manifest payloads: " + path);
    return codeEntries;
  }

  public static void main(String[] args) throws Exception {
    require(args.length == 3, "Usage: AndroidArtworkDownloadSize.java <AAB> <APKS> <ARTWORK_MANIFEST>");
    Path aab = Path.of(args[0]);
    Path apksPath = Path.of(args[1]);
    Path artworkManifestPath = Path.of(args[2]);
    ArtworkManifest lock = artworkManifest(artworkManifestPath);
    Map<String, EntryDigest> expected = lock.assets();
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
      aabArtwork(bundle, expected);
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
        masters.put(master, expected.size());
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
        masterRows.add("{\"path\":" + q(master) + ",\"assetCount\":" + expected.size()
            + ",\"rawApkBytes\":" + raw + ",\"vendorDownloadBytes\":" + size
            + ",\"codeEntries\":[" + codeEntries.stream().map(AndroidArtworkDownloadSize::q)
                .collect(java.util.stream.Collectors.joining(",")) + "]}");
      }
    }
    System.out.println("{\"schemaVersion\":1,\"measurementMethod\":"
        + q("bundletool ApkSizeUtils.getCompressedSizeByApkPaths; min(raw APK bytes, vendor GZIP bytes)")
        + ",\"aabSha256\":" + q(fileDigest(aab)) + ",\"apksSha256\":" + q(fileDigest(apksPath))
        + ",\"artworkManifestSha256\":" + q(fileDigest(artworkManifestPath))
        + ",\"groups\":{" + lock.groups().entrySet().stream().map(e -> q(e.getKey()) + ":" + e.getValue())
            .collect(java.util.stream.Collectors.joining(",")) + "}"
        + ",\"module\":" + q(MODULE) + ",\"baseMinSdk\":" + baseSdk
        + ",\"artworkMinSdk\":" + moduleSdk + ",\"variantCount\":" + toc.getVariantCount()
        + ",\"assetCount\":" + expected.size() + ",\"noPackagedDexOrNativeCode\":" + noPackagedCode
        + ",\"noPackagedApplicationCode\":true"
        + ",\"moduleLowerBoundBytes\":" + lowerBound
        + ",\"variants\":[" + String.join(",", variants) + "]"
        + ",\"masters\":[" + String.join(",", masterRows) + "]}");
  }
}
