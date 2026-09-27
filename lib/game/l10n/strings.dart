import 'package:flutter/foundation.dart';

import '../data/part.dart';
import '../data/vehicles.dart';
import 'bn.dart';
import 'en.dart';

class Lang {
  const Lang(this.code, this.name, this.english);
  final String code;
  final String name;
  final String english;
}

/// To add a language: create `<code>.dart` with the same keys as `bn.dart`
/// and list it here and in [translations].
const languages = [
  Lang('en', 'English', 'English'),
  Lang('bn', 'বাংলা', 'Bangla'),
];

const Map<String, Map<String, String>> translations = {'en': en, 'bn': bn};

final appLang = ValueNotifier<String>('en');

/// Looks up [key] in the current language, falling back to English.
/// `{name}` placeholders are replaced from [args].
String tr(String key, [Map<String, Object> args = const {}]) {
  var s = translations[appLang.value]?[key] ?? en[key] ?? key;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String vehicleName(Vehicle v) => tr('veh_${v.id}');

String groupName(PartGroup g) => tr('grp_${g.name}');

/// Newer models reuse the parts (and translations) of a base vehicle.
const _family = {'suv': 'car', 'sportbike': 'motorbike'};

String? _partText(String kind, Vehicle v, VehiclePart p) {
  final t = translations[appLang.value];
  final base = _family[v.id];
  return t?['$kind.${v.id}.${p.id}'] ??
      (base == null ? null : t?['$kind.$base.${p.id}']);
}

String partName(Vehicle v, VehiclePart p) => _partText('p', v, p) ?? p.name;

String partInfo(Vehicle v, VehiclePart p) => _partText('i', v, p) ?? p.info;
