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
      final unitPart = n % 10 != 0 ? " ${_units[n % 10]}" : "";
      return "${_tens[n ~/ 10]}$unitPart";
    }

    if (n < 1000) {
      final rem = n % 100;
      final remPart = rem != 0 ? " ${_convertNumber(rem)}" : "";
      return "${_units[n ~/ 100]} Hundred$remPart";
    }

    if (n < 100000) {
      final rem = n % 1000;
      final remPart = rem != 0 ? " ${_convertNumber(rem)}" : "";
      return "${_convertNumber(n ~/ 1000)} Thousand$remPart";
    }

    if (n < 10000000) {
      final rem = n % 100000;
      final remPart = rem != 0 ? " ${_convertNumber(rem)}" : "";
      return "${_convertNumber(n ~/ 100000)} Lakh$remPart";
    }

    final rem = n % 10000000;
    final remPart = rem != 0 ? " ${_convertNumber(rem)}" : "";
    return "${_convertNumber(n ~/ 10000000)} Crore$remPart";
  }
}
