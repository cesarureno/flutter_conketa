import 'dart:convert';
import 'dart:io' show Platform;

import 'package:conekta/paymentMethod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class ConektaFlutterTokenizer {
  final String _publickey = "key_C7r8TsUNuVixS3jwXYrivVg";
  final String _conektaTokenizationApiUrl = "https://api.conekta.io/tokens";

  dynamic _buildConektaTokenizeRequestHeaders() {
    return {
      "Accept": "application/vnd.conekta-v1.0.0+json",
      "Conekta-Client-User-Agent":
          "{\"agent\": \"Conekta JavascriptBindings-AJAX/v1.0.0 build 2.0.14\"}",
      "Authorization": "Basic " + _encodeKey()
    };
  }

  String _encodeKey() {
    List<int> utf16KeyBytes = _publickey.codeUnits;
    return const Base64Encoder().convert(utf16KeyBytes);
  }

  Future<String?> _getDeviceId() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      return androidDeviceInfo.androidId;
    }

    IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
    return iosDeviceInfo.identifierForVendor;
  }

  dynamic _buildUrlEncodedForm(PaymentMethod paymentMethod) async {
    String? deviceId = await _getDeviceId();

    return {
      "card[name]": paymentMethod.name,
      "card[number]": paymentMethod.number,
      "card[exp_month]": paymentMethod.expirationMonth,
      "card[exp_year]": paymentMethod.expirationYear,
      "card[cvc]": paymentMethod.cvc,
      "card[device_fingerprint]": deviceId
    };
  }

  Future<dynamic> tokenizePaymentMethod(PaymentMethod paymentMethod) async {
    dynamic requestHeaders = _buildConektaTokenizeRequestHeaders();
    dynamic requestBody = await _buildUrlEncodedForm(paymentMethod);

    var conektaResponse = await http.post(Uri.parse(_conektaTokenizationApiUrl),
        headers: requestHeaders, body: requestBody);

    if (conektaResponse.statusCode == 200) {
      return json.decode(conektaResponse.body);
    }

    return null;
  }
}
