import 'dart:io';
import 'dart:typed_data';

Uint8List? extractCoverArtSync(File file) {
  try {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 10) return null;

    if (!(bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33)) {
      return null;
    }

    int offset = 10;

    int synchsafeToInt(List<int> bytes, int start) {
      int result = 0;
      for (int i = 0; i < 4; i++) {
        result = (result << 7) | (bytes[start + i] & 0x7F);
      }
      return result;
    }

    while (offset < bytes.length - 10) {
      final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      offset += 4;

      if (offset + 4 > bytes.length) break;

      final size = synchsafeToInt(bytes, offset);
      offset += 4;

      if (offset + 2 > bytes.length) break;
      offset += 2;

      if (size <= 0 || offset + size > bytes.length) break;

      if (frameId == 'APIC') {
        final data = bytes.sublist(offset, offset + size);
        int dataOffset = 0;

        if (dataOffset < data.length) dataOffset++;
        if (dataOffset >= data.length) break;

        while (dataOffset < data.length && data[dataOffset] != 0) {
          dataOffset++;
        }

        dataOffset++;

        if (dataOffset < data.length) dataOffset++;

        if (dataOffset < data.length) {
          final imageData = data.sublist(dataOffset);
          return Uint8List.fromList(imageData);
        }
      }

      offset += size;
    }
  } catch (_) {}

  return null;
}

Uint8List? extractCoverArtFromPath(String filePath) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;
    return extractCoverArtSync(file);
  } catch (_) {
    return null;
  }
}
