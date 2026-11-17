import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Base64;
import java.util.HexFormat;
import java.util.zip.Adler32;

/** Executes the actual production classifier against reviewed bytes and mutations. */
public final class AndroidArtworkMarkerTest {
  private static final String BASELINE =
      "ZGV4CjAzNwCYnMmssGHtkD5UGzk6/3l8gRhwz4c4qp7sAgAAcAAAAHhWNBIAAAAAAAAAAHACAAAG" +
      "AAAAcAAAAAMAAACIAAAAAQAAAJQAAAAAAAAAAAAAAAIAAACgAAAAAQAAALAAAAAcAgAA0AAAAOgA" +
      "AADwAAAAGwEAAC8BAAA7AQAAPgEAAAEAAAACAAAABAAAAAQAAAACAAAAAAAAAAAAAAAAAAAAAQAA" +
      "AAAAAAAAAAAAEQAAAAEAAAAAAAAA/////wAAAABkAgAAAAAAAAEAAQABAAAAAAAAAAQAAABwEAEA" +
      "AAAOAAY8aW5pdD4AKUxjb20vc3VqaW5hcmluL2tvX2xlcm5lbl9hcHAvY19hcnR3b3JrL1I7ABJM" +
      "amF2YS9sYW5nL09iamVjdDsAClNvdXJjZUZpbGUAAVYAowJ+flI4eyJiYWNrZW5kIjoiZGV4Iiwi" +
      "Y29tcGlsYXRpb24tbW9kZSI6InJlbGVhc2UiLCJkZXN1Z2FyZWQtbGlicmFyeS1pZGVudGlmaWVy" +
      "cyI6WyJjb20udG9vbHMuYW5kcm9pZDpkZXN1Z2FyX2pka19saWJzX2NvbmZpZ3VyYXRpb246Mi4x" +
      "LjQiXSwiaGFzLWNoZWNrc3VtcyI6ZmFsc2UsIm1pbi1hcGkiOjI0LCJwZy1tYXAtaWQiOiIxZjA0" +
      "Nzc0OWVlZDIxZDk4OTg4NmFmYTJkZTFiMDEwNzI2ZjE0YThiZGVlNzc2NTNiN2Y2MGQyYWVlMDc3" +
      "YmI5IiwicjgtbW9kZSI6ImZ1bGwiLCJ2ZXJzaW9uIjoiOS4wLjMyIn0AAAABAACCgATQAQAACgAA" +
      "AAAAAAABAAAAAAAAAAEAAAAGAAAAcAAAAAIAAAADAAAAiAAAAAMAAAABAAAAlAAAAAUAAAACAAAA" +
      "oAAAAAYAAAABAAAAsAAAAAEgAAABAAAA0AAAAAIgAAAGAAAA6AAAAAAgAAABAAAAZAIAAAAQAAAB" +
      "AAAAcAIAAA==";
  private static Method classifier;
  private static int cases;

  private static byte[] sha1(byte[] data) throws Exception {
    return MessageDigest.getInstance("SHA-1").digest(Arrays.copyOfRange(data, 32, data.length));
  }
  private static void repairChecksum(byte[] data) {
    Adler32 checksum = new Adler32();
    checksum.update(data, 12, data.length - 12);
    long value = checksum.getValue();
    for (int i = 0; i < 4; i++) { data[8 + i] = (byte) (value >>> (8 * i)); }
  }
  private static void repairHeaders(byte[] data) throws Exception {
    System.arraycopy(sha1(data), 0, data, 12, 20);
    repairChecksum(data);
  }
  private static int find(byte[] data, String text) {
    byte[] needle = text.getBytes(StandardCharsets.US_ASCII);
    for (int i = 0; i <= data.length - needle.length; i++) {
      if (Arrays.equals(data, i, i + needle.length, needle, 0, needle.length)) { return i; }
    }
    throw new AssertionError("Reviewed fixture string missing: " + text);
  }
  private static void check(String name, byte[] data, boolean expected) throws Exception {
    byte[] original = data.clone();
    boolean actual = (boolean) classifier.invoke(null, (Object) data);
    if (actual != expected) { throw new AssertionError(name + ": accepted=" + actual); }
    if (!Arrays.equals(original, data)) { throw new AssertionError(name + ": classifier changed input"); }
    cases++;
  }
  private static byte[] mapping(byte[] original, String id) throws Exception {
    byte[] data = original.clone();
    System.arraycopy(id.getBytes(StandardCharsets.US_ASCII), 0, data, 509, 64);
    repairHeaders(data);
    return data;
  }

  public static void main(String[] args) throws Exception {
    classifier = AndroidArtworkDownloadSize.class.getDeclaredMethod("isReviewedResourceMarker", byte[].class);
    classifier.setAccessible(true);
    byte[] original = Base64.getDecoder().decode(BASELINE);
    String digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(original));
    if (!digest.equals("89093ecf4efd0f3f3ef56065147c3c911d11a2b9a62488c60e237d3c6f14fdbb")) {
      throw new AssertionError("Fixture is not the independently reviewed marker");
    }
    check("reviewed baseline", original, true);
    byte[] ci = mapping(original, "00b323970721503d4a10824d7f8dacb191a87bac311f3d10559f1fefa7a534c6");
    if (!HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(ci))
        .equals("9858f5c19a40e08d4d2631b85c04f3999e292a657b4778cf9218bad7904f6872")) {
      throw new AssertionError("Reconstructed fixture differs from actual CI8066 DEX");
    }
    check("actual CI8066 bytes", ci, true);
    check("mapping all zero", mapping(original, "0".repeat(64)), true);
    check("mapping all f", mapping(original, "f".repeat(64)), true);

    byte[] changed = original.clone(); changed[8] ^= 1;
    check("corrupt Adler32", changed, false);
    changed = original.clone(); changed[12] ^= 1; repairChecksum(changed);
    check("corrupt SHA1 with valid Adler32", changed, false);
    changed = original.clone(); changed[224] ^= 1; repairHeaders(changed);
    check("changed constructor opcode with valid headers", changed, false);
    changed = original.clone(); changed[80] = 1; repairHeaders(changed);
    check("changed field table with valid headers", changed, false);
    changed = original.clone(); changed[find(changed, "/R;") + 1] = 'S'; repairHeaders(changed);
    check("changed class descriptor with valid headers", changed, false);
    changed = original.clone(); changed[find(changed, "SourceFile")] = 'X'; repairHeaders(changed);
    check("changed other string with valid headers", changed, false);
    changed = original.clone(); changed[find(changed, "9.0.32") + 5] = '3'; repairHeaders(changed);
    check("changed compiler metadata with valid headers", changed, false);
    changed = original.clone(); changed[509] = 'g'; repairHeaders(changed);
    check("nonhex mapping", changed, false);
    changed = original.clone(); changed[509] = 'A'; repairHeaders(changed);
    check("uppercase mapping", changed, false);
    changed = original.clone(); changed[573] = '`'; repairHeaders(changed);
    check("changed mapping context", changed, false);
    changed = original.clone();
    byte[] field = "\"pg-map-id\":\"".getBytes(StandardCharsets.US_ASCII);
    System.arraycopy(field, 0, changed, 350, field.length); repairHeaders(changed);
    check("duplicate mapping field", changed, false);
    changed = original.clone(); changed[0] = 'x'; repairHeaders(changed);
    check("changed DEX magic", changed, false);
    changed = original.clone(); changed[32] ^= 1; repairHeaders(changed);
    check("changed file size field with valid headers", changed, false);
    check("truncated DEX", Arrays.copyOf(original, 747), false);
    check("extra DEX byte", Arrays.copyOf(original, 749), false);
    System.out.println(cases + " marker policy cases passed (4 reviewed/mapping-only, 15 rejection cases).");
  }
}
