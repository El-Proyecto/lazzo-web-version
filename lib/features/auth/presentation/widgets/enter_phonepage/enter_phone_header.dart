import 'package:flutter/material.dart';
import './country_dropdown.dart';
//import '../../../../../shared/constants/countries.dart';
import '../../../data/models/country.dart';


class EnterPhoneHeader extends StatelessWidget {
  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final List<Country> countries;

  const EnterPhoneHeader({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your phone number',
            style: TextStyle(
              color: Color(0xFFF2F2F2),
              fontSize: 32,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'We’ll send you a verification code to confirm your number',
            style: TextStyle(
              color: Color(0xFFA5A5A5),
              fontSize: 22,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.27,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: CountryDropdown(
                  countries: countries,
                  initialCountry: selectedCountry,
                  onChanged: onCountryChanged,
                  
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: ShapeDecoration(
                    color: Color(0xFF2B2B2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Color(0xFFF2F2F2)),
                    decoration: InputDecoration(
                      hintText: 'e.g. 912345678',
                      hintStyle: TextStyle(
                        color: Color(0xFFA5A5A5),
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                        letterSpacing: 0.25,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}