class AppConstants {
  AppConstants._();

  static const String appName = 'FreightFlow';
  static const String appVersion = '1.0.0';

  // Freight rate defaults (₹ per kg)
  static const double baseRatePerKg    = 3.50;
  static const double expressRatePerKg = 6.00;
  static const double coldChainRate    = 9.50;

  // Operational thresholds
  static const double maxWeightPerTruck = 15000.0;  // kg
  static const double fuelAlertLevel    = 20.0;     // % remaining
  static const int    overdueTripsLimit = 3;

  // GST
  static const double gstRate = 0.18;

  static const List<String> vehicleTypes = [
    'Mini Truck (1 Ton)',
    'Pickup (2 Ton)',
    'Single Axle (5 Ton)',
    'Double Axle (10 Ton)',
    'Multi Axle (20+ Ton)',
  ];

  static const List<String> goodsCategories = [
    'General Cargo',
    'Fragile / Glassware',
    'Perishable / Cold Chain',
    'Hazardous Material',
    'Machinery & Equipment',
    'Textiles & Garments',
    'Agricultural Produce',
  ];

  static const List<String> majorCities = [
    'Ahmedabad, GJ', 'Rajkot, GJ', 'Surat, GJ', 'Vadodara, GJ',
    'Mumbai, MH', 'Pune, MH', 'Nagpur, MH',
    'Delhi, DL', 'Gurugram, HR',
    'Bangalore, KA', 'Chennai, TN', 'Hyderabad, TS',
    'Kolkata, WB', 'Jaipur, RJ', 'Lucknow, UP',
  ];
}
