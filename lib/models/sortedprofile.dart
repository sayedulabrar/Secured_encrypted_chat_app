import 'package:cryp_comm/models/profile.dart';

class SortedProfilesData {
  final List<Profile> profiles;
  final DateTime sortTimestamp;

  SortedProfilesData(this.profiles, this.sortTimestamp);

  bool get isEmpty => profiles.isEmpty;
  int get length => profiles.length;

  Iterable<Profile> where(bool Function(Profile) test) {
    return profiles.where(test);
  }

  Profile operator [](int index) => profiles[index];
}