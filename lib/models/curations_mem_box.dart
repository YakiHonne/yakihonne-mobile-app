import 'package:yakihonne/models/curation_model.dart';

class CurationsMemBox {
  Map<String, Curation> _curations = {};

  Map<String, Curation> get getCurations => _curations;

  Map<String, Curation> getAuthorsByList(List<String> curationsIds) {
    Map<String, Curation> curationsList = {};

    for (final curationId in curationsIds) {
      final curation = _curations[curationId];
      if (curation != null) {
        curationsList[curationId] = curation;
      }
    }

    return curationsList;
  }

  void setCurationsList(List<Curation> curationsList) {
    _curations.clear();
    for (final curation in curationsList) {
      _curations[curation.identifier] = curation;
    }
  }

  void addManyCurationsToCurationsList(List<Curation> curationsList) {
    for (final curation in curationsList) {
      if (_curations[curation.identifier] == null) {
        _curations[curation.identifier] = curation;
      }
    }
  }

  void addCurationToCurationsList(Curation curation) {
    if (_curations[curation.identifier] == null) {
      _curations[curation.identifier] = curation;
    }
  }
}
