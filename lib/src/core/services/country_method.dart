abstract class CountryMethod {
  static int methodFromCountry(String countryCode) {
    switch (countryCode) {
      case 'EG':
      case 'SA':
      case 'AE':
      case 'KW':
        return 5;
      case 'GB':
      case 'FR':
      case 'DE':
      case 'US':
        return 3;
      default:
        return 5;
    }
  }
}
