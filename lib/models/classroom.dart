/// Maps Chinese building name prefixes to English abbreviations.
///
/// Source: [OIA Guide for New Students](https://oia.ntut.edu.tw/var/file/32/1032/img/GuideForNewStudents.pdf).
const classroomPrefixes = {
  '科研大樓': 'HYTRB',
  '一教': '1TB',
  '二教': '2TB',
  '三教': '3TB',
  '四教': '4TB',
  '五教': '5TB',
  '六教': '6TB',
  '共同': 'GSB',
  '綜科': 'CB',
  '設計': 'DB',
  '土木': 'CEB',
  '億光': 'EB',
  '光華': 'GHB',
  '化工': 'ChemEB',
  '化學': 'ChemB',
  '先鋒': 'PIB',
};

/// Translates a Chinese classroom name to abbreviated English format.
///
/// Returns `null` if the building prefix is not in the dictionary.
String? translateClassroomName(String nameZh) {
  for (final MapEntry(key: prefix, value: abbrev)
      in classroomPrefixes.entries) {
    if (nameZh.startsWith(prefix)) {
      final room = nameZh.substring(prefix.length);
      return '$abbrev $room';
    }
  }
  return null;
}
