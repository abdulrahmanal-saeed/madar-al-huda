import 'package:adhan_dart/adhan_dart.dart';

/// The authorities whose angles and adjustments the prayer times follow.
enum PrayerMethod {
  egyptian,
  ummAlQura,
  dubai,
  qatar,
  kuwait,
  gulfRegion,
  jordan,
  morocco,
  algerian,
  tunisia,
  turkiye,
  karachi,
  singapore,
  indonesian,
  northAmerica,
  moonsightingCommittee,
  france,
  russia,
  muslimWorldLeague;

  CalculationParameters parameters() => switch (this) {
    egyptian => CalculationMethodParameters.egyptian(),
    ummAlQura => CalculationMethodParameters.ummAlQura(),
    dubai => CalculationMethodParameters.dubai(),
    qatar => CalculationMethodParameters.qatar(),
    kuwait => CalculationMethodParameters.kuwait(),
    gulfRegion => CalculationMethodParameters.gulfRegion(),
    jordan => CalculationMethodParameters.jordan(),
    morocco => CalculationMethodParameters.morocco(),
    algerian => CalculationMethodParameters.algerian(),
    tunisia => CalculationMethodParameters.tunisia(),
    turkiye => CalculationMethodParameters.turkiye(),
    karachi => CalculationMethodParameters.karachi(),
    singapore => CalculationMethodParameters.singapore(),
    indonesian => CalculationMethodParameters.indonesian(),
    northAmerica => CalculationMethodParameters.northAmerica(),
    moonsightingCommittee =>
      CalculationMethodParameters.moonsightingCommittee(),
    france => CalculationMethodParameters.france(),
    russia => CalculationMethodParameters.russia(),
    muslimWorldLeague => CalculationMethodParameters.muslimWorldLeague(),
  };

  /// The method a country's own authority publishes, or the Muslim World
  /// League's where there is none in the list. Users can override it.
  static PrayerMethod forCountry(String country) => switch (country) {
    'EG' || 'SD' || 'SS' || 'LY' || 'SY' || 'IQ' || 'LB' => egyptian,
    'SA' || 'YE' => ummAlQura,
    'AE' => dubai,
    'QA' => qatar,
    'KW' => kuwait,
    'BH' || 'OM' => gulfRegion,
    'JO' || 'PS' => jordan,
    'MA' => morocco,
    'DZ' => algerian,
    'TN' => tunisia,
    'TR' => turkiye,
    'PK' || 'IN' || 'BD' || 'AF' => karachi,
    'SG' || 'MY' || 'BN' => singapore,
    'ID' => indonesian,
    'US' || 'CA' => northAmerica,
    'FR' => france,
    'RU' => russia,
    _ => muslimWorldLeague,
  };
}
