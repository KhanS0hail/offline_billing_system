class StateCodes {
  static const Map<String, String> _codeToName = {
    '01': '01 - Jammu & Kashmir',
    '02': '02 - Himachal Pradesh',
    '03': '03 - Punjab',
    '04': '04 - Chandigarh',
    '05': '05 - Uttarakhand',
    '06': '06 - Haryana',
    '07': '07 - Delhi',
    '08': '08 - Rajasthan',
    '09': '09 - Uttar Pradesh',
    '10': '10 - Bihar',
    '11': '11 - Sikkim',
    '12': '12 - Arunachal Pradesh',
    '13': '13 - Nagaland',
    '14': '14 - Manipur',
    '15': '15 - Mizoram',
    '16': '16 - Tripura',
    '17': '17 - Meghalaya',
    '18': '18 - Assam',
    '19': '19 - West Bengal',
    '20': '20 - Jharkhand',
    '21': '21 - Odisha',
    '22': '22 - Chhattisgarh',
    '23': '23 - Madhya Pradesh',
    '24': '24 - Gujarat',
    '26': '26 - Dadra & Nagar Haveli and Daman & Diu',
    '27': '27 - Maharashtra',
    '29': '29 - Karnataka',
    '30': '30 - Goa',
    '31': '31 - Lakshadweep',
    '32': '32 - Kerala',
    '33': '33 - Tamil Nadu',
    '34': '34 - Puducherry',
    '35': '35 - Andaman & Nicobar Islands',
    '36': '36 - Telangana',
    '37': '37 - Andhra Pradesh',
    '38': '38 - Ladakh',
  };

  static String getFormattedState(String? codeOrName) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return '';
    final trimmed = codeOrName.trim();
    if (_codeToName.containsKey(trimmed)) {
      return _codeToName[trimmed]!;
    }
    // Try padding single digit string e.g. "7" -> "07"
    if (trimmed.length == 1 && _codeToName.containsKey('0$trimmed')) {
      return _codeToName['0$trimmed']!;
    }
    return trimmed;
  }
}
