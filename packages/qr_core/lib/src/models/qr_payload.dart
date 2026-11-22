import 'qr_enums.dart';
import '../validators/schema_validator.dart';

/// Base class for all structured QR payloads.
abstract class QrPayload {
  const QrPayload();

  QrPayloadType get type;
  String toRawPayload();
  Map<String, dynamic> toJson();
  ValidationResult validate();
}

/// 1. Web URL Payload (`https://` or `http://`)
class UrlPayload extends QrPayload {
  final Uri uri;

  const UrlPayload({required this.uri});

  @override
  QrPayloadType get type => QrPayloadType.url;

  String get host => uri.host;
  String get scheme => uri.scheme;
  String get path => uri.path;
  Map<String, String> get queryParameters => uri.queryParameters;

  @override
  String toRawPayload() => uri.toString();

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'url': uri.toString(),
    'host': host,
    'scheme': scheme,
    'path': path,
    'queryParams': queryParameters,
  };

  @override
  ValidationResult validate() => SchemaValidator.validateUrl(uri.toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UrlPayload && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;
}

/// 2. Wi-Fi Network Credentials Payload (`WIFI:S:...;T:...;P:...;H:...;;`)
class WifiPayload extends QrPayload {
  final String ssid;
  final String password;
  final WifiAuthType authType;
  final bool isHidden;

  const WifiPayload({
    required this.ssid,
    this.password = '',
    this.authType = WifiAuthType.wpa,
    this.isHidden = false,
  });

  @override
  QrPayloadType get type => QrPayloadType.wifi;

  @override
  String toRawPayload() {
    final tStr = authType == WifiAuthType.wpa
        ? 'WPA'
        : authType == WifiAuthType.wpa2
            ? 'WPA2'
            : authType == WifiAuthType.wpa3
                ? 'WPA3'
                : authType == WifiAuthType.wep
                    ? 'WEP'
                    : 'nopass';
    final pStr = authType == WifiAuthType.none ? '' : password;
    return 'WIFI:S:$ssid;T:$tStr;P:$pStr;H:$isHidden;;';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'ssid': ssid,
    'password': password,
    'authType': authType.name,
    'isHidden': isHidden,
  };

  @override
  ValidationResult validate() {
    if (ssid.trim().isEmpty) return const ValidationResult.invalid('SSID cannot be empty');
    if (authType != WifiAuthType.none && password.isEmpty) {
      return const ValidationResult.invalid('Password cannot be empty for secured networks');
    }
    return const ValidationResult.valid();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WifiPayload &&
          other.ssid == ssid &&
          other.password == password &&
          other.authType == authType &&
          other.isHidden == isHidden);

  @override
  int get hashCode => Object.hash(ssid, password, authType, isHidden);
}

/// 3. vCard 3.0 / 4.0 Contact Payload
class VCardPayload extends QrPayload {
  final String formattedName;
  final String? firstName;
  final String? lastName;
  final String? organization;
  final String? title;
  final List<String> phoneNumbers;
  final List<String> emails;
  final List<String> urls;
  final List<String> addresses;
  final String? note;

  const VCardPayload({
    required this.formattedName,
    this.firstName,
    this.lastName,
    this.organization,
    this.title,
    this.phoneNumbers = const [],
    this.emails = const [],
    this.urls = const [],
    this.addresses = const [],
    this.note,
  });

  @override
  QrPayloadType get type => QrPayloadType.vcard;

  @override
  String toRawPayload() {
    final buffer = StringBuffer('BEGIN:VCARD\nVERSION:3.0\n');
    buffer.writeln('FN:$formattedName');
    if (lastName != null || firstName != null) {
      buffer.writeln('N:${lastName ?? ''};${firstName ?? ''};;;');
    }
    if (organization != null) buffer.writeln('ORG:$organization');
    if (title != null) buffer.writeln('TITLE:$title');
    for (final phone in phoneNumbers) {
      buffer.writeln('TEL:$phone');
    }
    for (final email in emails) {
      buffer.writeln('EMAIL:$email');
    }
    for (final url in urls) {
      buffer.writeln('URL:$url');
    }
    for (final addr in addresses) {
      buffer.writeln('ADR:;;$addr;;;;');
    }
    if (note != null) buffer.writeln('NOTE:$note');
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'formattedName': formattedName,
    'firstName': firstName,
    'lastName': lastName,
    'organization': organization,
    'title': title,
    'phoneNumbers': phoneNumbers,
    'emails': emails,
    'urls': urls,
    'addresses': addresses,
    'note': note,
  };

  @override
  ValidationResult validate() {
    if (formattedName.trim().isEmpty) {
      return const ValidationResult.invalid('vCard formatted name (FN) cannot be empty');
    }
    for (final email in emails) {
      final res = SchemaValidator.validateEmail(email);
      if (!res.isValid) return res;
    }
    return const ValidationResult.valid();
  }
}

/// 4. MeCard Contact Payload
class MeCardPayload extends QrPayload {
  final String name;
  final String? telephone;
  final String? email;
  final String? url;
  final String? note;
  final String? address;

  const MeCardPayload({
    required this.name,
    this.telephone,
    this.email,
    this.url,
    this.note,
    this.address,
  });

  @override
  QrPayloadType get type => QrPayloadType.mecard;

  @override
  String toRawPayload() {
    final buffer = StringBuffer('MECARD:N:$name;');
    if (telephone != null) buffer.write('TEL:$telephone;');
    if (email != null) buffer.write('EMAIL:$email;');
    if (url != null) buffer.write('URL:$url;');
    if (note != null) buffer.write('NOTE:$note;');
    if (address != null) buffer.write('ADR:$address;');
    buffer.write(';');
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'telephone': telephone,
    'email': email,
    'url': url,
    'note': note,
    'address': address,
  };

  @override
  ValidationResult validate() {
    if (name.trim().isEmpty) return const ValidationResult.invalid('MeCard name cannot be empty');
    if (email != null) {
      final res = SchemaValidator.validateEmail(email!);
      if (!res.isValid) return res;
    }
    return const ValidationResult.valid();
  }
}

/// 5. Geographic Coordinates (`geo:lat,lng[,alt][?q=query]`)
class GeoPayload extends QrPayload {
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? query;

  const GeoPayload({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.query,
  });

  @override
  QrPayloadType get type => QrPayloadType.geo;

  @override
  String toRawPayload() {
    var raw = 'geo:$latitude,$longitude';
    if (altitude != null) raw += ',$altitude';
    if (query != null && query!.isNotEmpty) raw += '?q=${Uri.encodeComponent(query!)}';
    return raw;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'query': query,
  };

  @override
  ValidationResult validate() => SchemaValidator.validateCoordinates(latitude, longitude);
}

/// 6. iCalendar VEVENT Event Payload
class EventPayload extends QrPayload {
  final String summary;
  final DateTime dtStart;
  final DateTime? dtEnd;
  final String? location;
  final String? description;
  final bool isAllDay;

  const EventPayload({
    required this.summary,
    required this.dtStart,
    this.dtEnd,
    this.location,
    this.description,
    this.isAllDay = false,
  });

  @override
  QrPayloadType get type => QrPayloadType.event;

  @override
  String toRawPayload() {
    final buffer = StringBuffer('BEGIN:VEVENT\n');
    buffer.writeln('SUMMARY:$summary');
    buffer.writeln('DTSTART:${_formatDate(dtStart)}');
    if (dtEnd != null) {
      buffer.writeln('DTEND:${_formatDate(dtEnd!)}');
    }
    if (location != null) buffer.writeln('LOCATION:$location');
    if (description != null) buffer.writeln('DESCRIPTION:$description');
    buffer.write('END:VEVENT');
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'summary': summary,
    'dtStart': dtStart.toIso8601String(),
    'dtEnd': dtEnd?.toIso8601String(),
    'location': location,
    'description': description,
    'isAllDay': isAllDay,
  };

  @override
  ValidationResult validate() {
    if (summary.trim().isEmpty) return const ValidationResult.invalid('Event summary cannot be empty');
    if (dtEnd != null && dtEnd!.isBefore(dtStart)) {
      return const ValidationResult.invalid('Event end time cannot be before start time');
    }
    return const ValidationResult.valid();
  }
}

/// 7. Email Payload (`mailto:...` or `MATMSG:...`)
class EmailPayload extends QrPayload {
  final String to;
  final String? subject;
  final String? body;
  final String? cc;

  const EmailPayload({
    required this.to,
    this.subject,
    this.body,
    this.cc,
  });

  @override
  QrPayloadType get type => QrPayloadType.email;

  @override
  String toRawPayload() {
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject!;
    if (body != null) params['body'] = body!;
    if (cc != null) params['cc'] = cc!;
    final uri = Uri(scheme: 'mailto', path: to, queryParameters: params.isEmpty ? null : params);
    return uri.toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'to': to,
    'subject': subject,
    'body': body,
    'cc': cc,
  };

  @override
  ValidationResult validate() => SchemaValidator.validateEmail(to);
}

/// 8. SMS Payload (`sms:...` or `smsto:...`)
class SmsPayload extends QrPayload {
  final String phoneNumber;
  final String? message;

  const SmsPayload({
    required this.phoneNumber,
    this.message,
  });

  @override
  QrPayloadType get type => QrPayloadType.sms;

  @override
  String toRawPayload() {
    if (message != null && message!.isNotEmpty) {
      return 'sms:$phoneNumber?body=${Uri.encodeComponent(message!)}';
    }
    return 'sms:$phoneNumber';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'phoneNumber': phoneNumber,
    'message': message,
  };

  @override
  ValidationResult validate() {
    if (phoneNumber.trim().isEmpty) {
      return const ValidationResult.invalid('SMS phone number cannot be empty');
    }
    return const ValidationResult.valid();
  }
}

/// 9. Telephone Payload (`tel:...`)
class TelPayload extends QrPayload {
  final String phoneNumber;

  const TelPayload({required this.phoneNumber});

  @override
  QrPayloadType get type => QrPayloadType.tel;

  @override
  String toRawPayload() => 'tel:$phoneNumber';

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'phoneNumber': phoneNumber,
  };

  @override
  ValidationResult validate() {
    if (phoneNumber.trim().isEmpty) {
      return const ValidationResult.invalid('Telephone number cannot be empty');
    }
    return const ValidationResult.valid();
  }
}

/// 10. OTP / 2FA Authenticator Payload (`otpauth://totp/...` or `otpauth://hotp/...`)
class OtpAuthPayload extends QrPayload {
  final OtpType otpType;
  final String accountName;
  final String secret;
  final String? issuer;
  final OtpAlgorithm algorithm;
  final int digits;
  final int period;
  final int? counter;

  const OtpAuthPayload({
    this.otpType = OtpType.totp,
    required this.accountName,
    required this.secret,
    this.issuer,
    this.algorithm = OtpAlgorithm.sha1,
    this.digits = 6,
    this.period = 30,
    this.counter,
  });

  @override
  QrPayloadType get type => QrPayloadType.otpauth;

  @override
  String toRawPayload() {
    final typeStr = otpType.name;
    final label = issuer != null ? '${Uri.encodeComponent(issuer!)}:${Uri.encodeComponent(accountName)}' : Uri.encodeComponent(accountName);
    final params = <String, String>{
      'secret': secret,
      'algorithm': algorithm.name.toUpperCase(),
      'digits': digits.toString(),
    };
    if (issuer != null) params['issuer'] = issuer!;
    if (otpType == OtpType.totp) {
      params['period'] = period.toString();
    } else if (counter != null) {
      params['counter'] = counter.toString();
    }
    return Uri(scheme: 'otpauth', host: typeStr, path: '/$label', queryParameters: params).toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'otpType': otpType.name,
    'accountName': accountName,
    'secret': secret,
    'issuer': issuer,
    'algorithm': algorithm.name,
    'digits': digits,
    'period': period,
    'counter': counter,
  };

  @override
  ValidationResult validate() {
    if (accountName.trim().isEmpty) return const ValidationResult.invalid('Account name cannot be empty');
    if (digits != 6 && digits != 8) return const ValidationResult.invalid('Digits must be 6 or 8');
    if (period <= 0) return const ValidationResult.invalid('Period must be greater than 0');
    return SchemaValidator.validateBase32Secret(secret);
  }
}

/// 11. UPI Payment Payload (`upi://pay?...`)
class UpiPaymentPayload extends QrPayload {
  final String payeeVpa;
  final String payeeName;
  final double? amount;
  final String currency;
  final String? transactionNote;
  final String? merchantCode;
  final String? transactionRef;

  const UpiPaymentPayload({
    required this.payeeVpa,
    required this.payeeName,
    this.amount,
    this.currency = 'INR',
    this.transactionNote,
    this.merchantCode,
    this.transactionRef,
  });

  @override
  QrPayloadType get type => QrPayloadType.upi;

  @override
  String toRawPayload() {
    final params = <String, String>{
      'pa': payeeVpa,
      'pn': payeeName,
      'cu': currency,
    };
    if (amount != null) params['am'] = amount!.toStringAsFixed(2);
    if (transactionNote != null) params['tn'] = transactionNote!;
    if (merchantCode != null) params['mc'] = merchantCode!;
    if (transactionRef != null) params['tr'] = transactionRef!;
    return Uri(scheme: 'upi', host: 'pay', queryParameters: params).toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'payeeVpa': payeeVpa,
    'payeeName': payeeName,
    'amount': amount,
    'currency': currency,
    'transactionNote': transactionNote,
    'merchantCode': merchantCode,
    'transactionRef': transactionRef,
  };

  @override
  ValidationResult validate() {
    final vpaRes = SchemaValidator.validateUpiVpa(payeeVpa);
    if (!vpaRes.isValid) return vpaRes;
    if (payeeName.trim().isEmpty) return const ValidationResult.invalid('Payee name cannot be empty');
    if (amount != null && amount! <= 0) return const ValidationResult.invalid('Amount must be positive');
    return const ValidationResult.valid();
  }
}

/// 12. European EPC / SEPA Payment QR Payload
class EpcPaymentPayload extends QrPayload {
  final String bic;
  final String recipientName;
  final String iban;
  final double? amount;
  final String? remittanceInfo;

  const EpcPaymentPayload({
    required this.bic,
    required this.recipientName,
    required this.iban,
    this.amount,
    this.remittanceInfo,
  });

  @override
  QrPayloadType get type => QrPayloadType.epc;

  @override
  String toRawPayload() {
    final amtStr = amount != null ? 'EUR${amount!.toStringAsFixed(2)}' : '';
    final lines = [
      'BCD',
      '002',
      '1',
      'SCT',
      bic,
      recipientName,
      iban.replaceAll(' ', '').toUpperCase(),
      amtStr,
      '',
      remittanceInfo ?? '',
      '',
    ];
    return lines.join('\n');
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'bic': bic,
    'recipientName': recipientName,
    'iban': iban,
    'amount': amount,
    'remittanceInfo': remittanceInfo,
  };

  @override
  ValidationResult validate() {
    final ibanRes = SchemaValidator.validateIban(iban);
    if (!ibanRes.isValid) return ibanRes;
    if (recipientName.trim().isEmpty) return const ValidationResult.invalid('Recipient name cannot be empty');
    if (amount != null && amount! <= 0) return const ValidationResult.invalid('Amount must be positive');
    return const ValidationResult.valid();
  }
}

/// 13. Cryptocurrency Payment Payload (`bitcoin:...`, `ethereum:...`, etc.)
class CryptoPaymentPayload extends QrPayload {
  final CryptoCurrency currency;
  final String address;
  final String? amount;
  final String? label;
  final String? message;

  const CryptoPaymentPayload({
    required this.currency,
    required this.address,
    this.amount,
    this.label,
    this.message,
  });

  @override
  QrPayloadType get type => QrPayloadType.crypto;

  @override
  String toRawPayload() {
    final scheme = currency.name;
    final params = <String, String>{};
    if (amount != null) params['amount'] = amount!;
    if (label != null) params['label'] = label!;
    if (message != null) params['message'] = message!;
    final query = params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    return '$scheme:$address$query';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'currency': currency.name,
    'address': address,
    'amount': amount,
    'label': label,
    'message': message,
  };

  @override
  ValidationResult validate() {
    if (address.trim().isEmpty) return const ValidationResult.invalid('Crypto address cannot be empty');
    return const ValidationResult.valid();
  }
}

/// 14. GS1 Digital Link & Application Identifier Payload
class Gs1DigitalLinkPayload extends QrPayload {
  final String gtin;
  final String? serialNumber;
  final String? batchLot;
  final String? expiryDate;
  final Map<String, String> additionalAis;

  const Gs1DigitalLinkPayload({
    required this.gtin,
    this.serialNumber,
    this.batchLot,
    this.expiryDate,
    this.additionalAis = const {},
  });

  @override
  QrPayloadType get type => QrPayloadType.gs1;

  @override
  String toRawPayload() {
    var url = 'https://id.gs1.org/01/$gtin';
    if (serialNumber != null) url += '/21/$serialNumber';
    final queryParams = <String, String>{};
    if (batchLot != null) queryParams['10'] = batchLot!;
    if (expiryDate != null) queryParams['17'] = expiryDate!;
    queryParams.addAll(additionalAis);
    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }
    return url;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'gtin': gtin,
    'serialNumber': serialNumber,
    'batchLot': batchLot,
    'expiryDate': expiryDate,
    'additionalAis': additionalAis,
  };

  @override
  ValidationResult validate() {
    if (gtin.trim().isEmpty) return const ValidationResult.invalid('GTIN cannot be empty');
    final cleanGtin = gtin.replaceAll(RegExp(r'\D'), '');
    if (cleanGtin.length != 8 && cleanGtin.length != 12 && cleanGtin.length != 13 && cleanGtin.length != 14) {
      return const ValidationResult.invalid('GTIN must be 8, 12, 13, or 14 numeric digits');
    }
    return const ValidationResult.valid();
  }
}

/// 15. Plain Text & Structured JSON Payload
class PlainTextPayload extends QrPayload {
  final String text;
  final bool isJson;
  final dynamic jsonData;

  const PlainTextPayload({
    required this.text,
    this.isJson = false,
    this.jsonData,
  });

  @override
  QrPayloadType get type => QrPayloadType.plainText;

  @override
  String toRawPayload() => text;

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'text': text,
    'isJson': isJson,
    'jsonData': jsonData,
  };

  @override
  ValidationResult validate() {
    if (text.isEmpty) return const ValidationResult.invalid('Text cannot be empty');
    return const ValidationResult.valid();
  }
}
