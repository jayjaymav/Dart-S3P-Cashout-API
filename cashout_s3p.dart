import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class HmacService {
  final String s3pUrl;
  final String s3pKey;
  final String s3pSecret;

  HmacService(this.s3pUrl, this.s3pKey, this.s3pSecret);

  // Generate HMAC-based authentication header
  String generateAuthHeader(String httpMethod,
      {Map<String, String>? queryParams, Map<String, dynamic>? requestData}) {
    queryParams ??= {};
    requestData ??= {};

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String nonce = timestamp;

    Map<String, String> s3pParams = {
      "s3pAuth_nonce": nonce,
      "s3pAuth_timestamp": timestamp,
      "s3pAuth_signature_method": "HMAC-SHA1",
      "s3pAuth_token": s3pKey
    };

    Map<String, dynamic> inputData = {}..addAll(queryParams)..addAll(requestData);
    //Map<String, dynamic> allParams = {}..addAll(inputData)..addAll(s3pParams);
    Map<String, dynamic> allParams = {}..addAll(inputData)..addAll(s3pParams);

  // Ensure all string values are trimmed
  allParams = allParams.map((k, v) {
    if (v is String) {
      return MapEntry(k, v.trim());
    }
    return MapEntry(k, v);
  });


    var sortedKeys = allParams.keys.toList()..sort();

    String parameterString = sortedKeys
    .map((key) => '$key=${allParams[key].toString().trim()}')
    .join('&');

    String baseString =
        '${httpMethod.toUpperCase()}&${Uri.encodeComponent(s3pUrl)}&${Uri.encodeComponent(parameterString)}';

    var key = utf8.encode(s3pSecret);
    var bytes = utf8.encode(baseString);
    var hmacSha1 = Hmac(sha1, key);
    var digest = hmacSha1.convert(bytes);

    String signature = base64.encode(digest.bytes);

    return 's3pAuth s3pAuth_timestamp="$timestamp", s3pAuth_signature="$signature", '
        's3pAuth_nonce="$nonce", s3pAuth_signature_method="HMAC-SHA1", '
        's3pAuth_token="$s3pKey"';
  }
}

Future<void> main() async {
  final s3pKey = "1c6fbc97-c186-4091-923c-e2535fe49215";
  final s3pSecret = "2b4e01f1-7600-4152-bd91-c309e4d91fb5";

  final baseUrl = "https://s3p.smobilpay.staging.maviance.info";

  // STEP 1: Get all available cashout services
  final cashoutUrl = "$baseUrl/v2/cashout";
  final cashoutService = HmacService(cashoutUrl, s3pKey, s3pSecret);

  final allServicesHeaders = {
    'Authorization': cashoutService.generateAuthHeader('GET'),
    'Content-Type': 'application/json'
  };

  final allServicesResp =
      await http.get(Uri.parse(cashoutUrl), headers: allServicesHeaders);
  print('1️⃣ All Cashout Services:\n${allServicesResp.body}');

  // STEP 2: Get a specific cashout service with serviceid
  final serviceId = "50053";
  final serviceQueryParams = {"serviceid": serviceId};

  final specificServiceHeaders = {
    'Authorization': cashoutService.generateAuthHeader('GET',
        queryParams: serviceQueryParams),
    'Content-Type': 'application/json'
  };

  final specificServiceResp = await http.get(
    Uri.parse(cashoutUrl).replace(queryParameters: serviceQueryParams),
    headers: specificServiceHeaders,
  );
  print('2️⃣ Specific Cashout Service:\n${specificServiceResp.body}');

  // STEP 3: Get a quote ID
  final quoteUrl = "$baseUrl/v2/quotestd";
  final quoteService = HmacService(quoteUrl, s3pKey, s3pSecret);

  final quoteData = {
    "payItemId": "S-112-949-CMORANGEMOMO-50053-900221-1",
    "amount": 100
  };

  final quoteHeaders = {
    'Authorization':
        quoteService.generateAuthHeader('POST', requestData: quoteData),
    'Content-Type': 'application/json'
  };

  final quoteResp = await http.post(Uri.parse(quoteUrl),
      headers: quoteHeaders, body: jsonEncode(quoteData));
  print('3️⃣ Quote Response:\n${quoteResp.body}');

  final quoteJson = jsonDecode(quoteResp.body);
  final quoteId = quoteJson["quoteId"];
  print('✅ Extracted Quote ID: $quoteId');

  // STEP 4: Collect with quote ID
  final collectUrl = "$baseUrl/v2/collectstd";
  final collectService = HmacService(collectUrl, s3pKey, s3pSecret);

  final collectData = {
    "quoteId": quoteId,
    "customerPhonenumber": "237654905897",
    "customerEmailaddress": "qas3p@yopmail.com",
    "customerName": "QA S3P",
    "customerAddress": "Mambanda Bonaberi",
    "serviceNumber": "698081976",
    "trid": "Jay-test-Cashout005"
  };

  final collectHeaders = {
    'Authorization':
        collectService.generateAuthHeader('POST', requestData: collectData),
    'Content-Type': 'application/json'
  };

  final collectResp = await http.post(Uri.parse(collectUrl),
      headers: collectHeaders, body: jsonEncode(collectData));
  print('4️⃣ Collect Response:\n${collectResp.body}');

  final collectJson = jsonDecode(collectResp.body);
  final ptn = collectJson["ptn"];
  print('✅ Extracted PTN: $ptn');

  // STEP 5: Wait 30 seconds then verify transaction status
  print('⏳ Waiting 30 seconds before verifying transaction...');
  await Future.delayed(Duration(seconds: 30));

  final verifyUrl = "$baseUrl/v2/verifytx";
  final verifyService = HmacService(verifyUrl, s3pKey, s3pSecret);

  final verifyQueryParams = {"ptn": ptn.toString()};

  final verifyHeaders = {
    'Authorization':
        verifyService.generateAuthHeader('GET', queryParams: verifyQueryParams),
    'Content-Type': 'application/json'
  };

  final verifyResp = await http.get(
    Uri.parse(verifyUrl).replace(queryParameters: verifyQueryParams),
    headers: verifyHeaders,
  );
  print('5️⃣ Verify Transaction Response:\n${verifyResp.body}');
}
