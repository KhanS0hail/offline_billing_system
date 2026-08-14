class NumberToWords {
  static const List<String> _units = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen"
  ];

  static const List<String> _tens = [
    "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
  ];

  static String convert(double amount) {
    if (amount <= 0) return "Zero Rupees Only";

    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    String rupeesInWords = _convertNumber(rupees);
    if (rupeesInWords.isEmpty) rupeesInWords = "Zero";

    String result = "Rupees $rupeesInWords";

    if (paise > 0) {
      String paiseInWords = _convertNumber(paise);
      result += " and $paiseInWords Paise";
    }

    return "$result Only";
  }

  static String _convertNumber(int n) {
    if (n < 0) return "";
    if (n == 0) return "";

    if (n < 20) return _units[n];

    if (n < 100) {
      return "${_tens[n ~/ 10]}${n % 10 != 0 ? " ${...}" : ""}".replaceAll("{...}", _units[n % 10]);
    }

    if (n < 1000) {
      return "${_units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${_convertNumber(n % 100)}" : ""}";
    }

    if (n < 100000) {
      return "${_convertNumber(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertNumber(n % 1000)}" : ""}";
    }

    if (n < 10000000) {
      return "${_convertNumber(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_convertNumber(n % 100000)}" : ""}";
    }

    return "${_convertNumber(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${_convertNumber(n % 10000000)}" : ""}";
  }
}
