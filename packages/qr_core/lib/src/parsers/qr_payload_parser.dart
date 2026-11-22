import 'dart:convert';
import '../models/qr_enums.dart';
import '../models/qr_payload.dart';

/// Universal parser and detector for all 15 supported QR payload formats.
class QrPayloadParser {
  /// Detect the payload type from raw string content.
  static QrPayloadType detectType(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (lower.contains('id.gs1.org/') || lower.contains('/01/')) {
        return QrPayloadType.gs1;
      }
      return QrPayloadType.url;
    }
    if (lower.startsWith('(01)') || lower.startsWith('01')) {
      final digits = lower.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 14) return QrPayloadType.gs1;
    }
    if (lower.startsWith('wifi:')) return QrPayloadType.wifi;
    if (lower.startsWith('begin:vcard')) return QrPayloadType.vcard;
    if (lower.startsWith('mecard:')) return QrPayloadType.mecard;
    if (lower.startsWith('geo:')) return QrPayloadType.geo;
    if (lower.startsWith('begin:vevent') || lower.contains('begin:vevent')) return QrPayloadType.event;
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) return QrPayloadType.email;
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) return QrPayloadType.sms;
    if (lower.startsWith('tel:')) return QrPayloadType.tel;
    if (lower.startsWith('otpauth://')) return QrPayloadType.otpauth;
    if (lower.startsWith('upi://')) return QrPayloadType.upi;
    if (trimmed.startsWith('BCD\n') || trimmed.startsWith('BCD\r\n')) return QrPayloadType.epc;
    if (lower.startsWith('bitcoin:') || lower.startsWith('ethereum:') || lower.startsWith('solana:') || lower.startsWith('litecoin:')) {
      return QrPayloadType.crypto;
    }
    return QrPayloadType.plainText;
  }

  /// Parse raw string into strongly-typed [QrPayload].
  static QrPayload parse(String raw) {
    final trimmed = raw.trim();
    final type = detectType(trimmed);

    switch (type) {
      case QrPayloadType.url:
        return _parseUrl(trimmed);
      case QrPayloadType.wifi:
        return _parseWifi(trimmed);
      case QrPayloadType.vcard:
        return _parseVCard(trimmed);
      case QrPayloadType.mecard:
        return _parseMeCard(trimmed);
      case QrPayloadType.geo:
        return _parseGeo(trimmed);
      case QrPayloadType.event:
        return _parseEvent(trimmed);
      case QrPayloadType.email:
        return _parseEmail(trimmed);
      case QrPayloadType.sms:
        return _parseSms(trimmed);
      case QrPayloadType.tel:
        return _parseTel(trimmed);
      case QrPayloadType.otpauth:
        return _parseOtpAuth(trimmed);
      case QrPayloadType.upi:
        return _parseUpi(trimmed);
      case QrPayloadType.epc:
        return _parseEpc(trimmed);
      case QrPayloadType.crypto:
        return _parseCrypto(trimmed);
      case QrPayloadType.gs1:
        return _parseGs1(trimmed);
      case QrPayloadType.plainText:
        return _parsePlainText(trimmed);
    }
  }

  static UrlPayload _parseUrl(String raw) {
    return UrlPayload(uri: Uri.parse(raw));
  }

  static WifiPayload _parseWifi(String raw) {
    // Format: WIFI:S:<SSID>;T:<WEP|WPA|nopass>;P:<password>;H:<true|false>;;
    final body = raw.substring(5);
    final segments = _splitEscaped(body, ';');

    String ssid = '';
    String password = '';
    WifiAuthType authType = WifiAuthType.wpa;
    bool isHidden = false;

    for (final seg in segments) {
      if (seg.isEmpty) continue;
      final colonIdx = seg.indexOf(':');
      if (colonIdx == -1) continue;
      final key = seg.substring(0, colonIdx).toUpperCase();
      final val = seg.substring(colonIdx + 1);

      switch (key) {
        case 'S':
          ssid = val;
          break;
        case 'P':
          password = val;
          break;
        case 'T':
          final upper = val.toUpperCase();
          if (upper == 'WEP') {
            authType = WifiAuthType.wep;
          } else if (upper == 'WPA2') {
            authType = WifiAuthType.wpa2;
          } else if (upper == 'WPA3') {
            authType = WifiAuthType.wpa3;
          } else if (upper == 'NOPASS' || upper == 'NONE') {
            authType = WifiAuthType.none;
          } else {
            authType = WifiAuthType.wpa;
          }
          break;
        case 'H':
          isHidden = val.toLowerCase() == 'true';
          break;
      }
    }

    return WifiPayload(
      ssid: ssid,
      password: password,
      authType: authType,
      isHidden: isHidden,
    );
  }

  static VCardPayload _parseVCard(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    String formattedName = '';
    String? firstName;
    String? lastName;
    String? organization;
    String? title;
    final phoneNumbers = <String>[];
    final emails = <String>[];
    final urls = <String>[];
    final addresses = <String>[];
    String? note;

    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      final keyFull = line.substring(0, colonIdx).toUpperCase();
      final val = line.substring(colonIdx + 1).trim();

      if (keyFull == 'FN') {
        formattedName = val;
      } else if (keyFull == 'N') {
        final parts = val.split(';');
        if (parts.isNotEmpty) lastName = parts[0].isNotEmpty ? parts[0] : null;
        if (parts.length > 1) firstName = parts[1].isNotEmpty ? parts[1] : null;
      } else if (keyFull == 'ORG') {
        organization = val;
      } else if (keyFull == 'TITLE') {
        title = val;
      } else if (keyFull.startsWith('TEL')) {
        phoneNumbers.add(val);
      } else if (keyFull.startsWith('EMAIL')) {
        emails.add(val);
      } else if (keyFull.startsWith('URL')) {
        urls.add(val);
      } else if (keyFull.startsWith('ADR')) {
        final clean = val.replaceAll(RegExp(r'^;+'), '').replaceAll(RegExp(r';+$'), '');
        addresses.add(clean.replaceAll(';', ', '));
      } else if (keyFull == 'NOTE') {
        note = val;
      }
    }

    if (formattedName.isEmpty) {
      formattedName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    if (formattedName.isEmpty) formattedName = 'Unknown Contact';

    return VCardPayload(
      formattedName: formattedName,
      firstName: firstName,
      lastName: lastName,
      organization: organization,
      title: title,
      phoneNumbers: phoneNumbers,
      emails: emails,
      urls: urls,
      addresses: addresses,
      note: note,
    );
  }

  static MeCardPayload _parseMeCard(String raw) {
    final body = raw.substring(7);
    final segments = _splitEscaped(body, ';');

    String name = '';
    String? tel;
    String? email;
    String? url;
    String? note;
    String? address;

    for (final seg in segments) {
      if (seg.isEmpty) continue;
      final colonIdx = seg.indexOf(':');
      if (colonIdx == -1) continue;
      final key = seg.substring(0, colonIdx).toUpperCase();
      final val = seg.substring(colonIdx + 1);

      switch (key) {
        case 'N':
          name = val;
          break;
        case 'TEL':
          tel = val;
          break;
        case 'EMAIL':
          email = val;
          break;
        case 'URL':
          url = val;
          break;
        case 'NOTE':
          note = val;
          break;
        case 'ADR':
          address = val;
          break;
      }
    }

    return MeCardPayload(
      name: name.isEmpty ? 'Unknown' : name,
      telephone: tel,
      email: email,
      url: url,
      note: note,
      address: address,
    );
  }

  static GeoPayload _parseGeo(String raw) {
    // Format: geo:lat,lng[,alt][?q=query]
    final body = raw.substring(4);
    String coordsPart = body;
    String? query;

    final qIdx = body.indexOf('?');
    if (qIdx != -1) {
      coordsPart = body.substring(0, qIdx);
      final queryString = body.substring(qIdx + 1);
      final qParams = Uri.splitQueryString(queryString);
      query = qParams['q'];
    }

    final parts = coordsPart.split(',');
    final lat = double.tryParse(parts[0]) ?? 0.0;
    final lng = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0.0) : 0.0;
    final alt = parts.length > 2 ? double.tryParse(parts[2]) : null;

    return GeoPayload(
      latitude: lat,
      longitude: lng,
      altitude: alt,
      query: query,
    );
  }

  static EventPayload _parseEvent(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    String summary = 'Event';
    DateTime dtStart = DateTime.now();
    DateTime? dtEnd;
    String? location;
    String? description;

    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      final key = line.substring(0, colonIdx).toUpperCase();
      final val = line.substring(colonIdx + 1).trim();

      if (key == 'SUMMARY') {
        summary = val;
      } else if (key == 'DTSTART') {
        dtStart = _parseICalDate(val) ?? DateTime.now();
      } else if (key == 'DTEND') {
        dtEnd = _parseICalDate(val);
      } else if (key == 'LOCATION') {
        location = val;
      } else if (key == 'DESCRIPTION') {
        description = val;
      }
    }

    return EventPayload(
      summary: summary,
      dtStart: dtStart,
      dtEnd: dtEnd,
      location: location,
      description: description,
    );
  }

  static DateTime? _parseICalDate(String val) {
    final clean = val.replaceAll('-', '').replaceAll(':', '').replaceAll('Z', '');
    if (clean.length >= 8) {
      final y = int.tryParse(clean.substring(0, 4)) ?? 2000;
      final m = int.tryParse(clean.substring(4, 6)) ?? 1;
      final d = int.tryParse(clean.substring(6, 8)) ?? 1;
      var h = 0, min = 0, sec = 0;
      if (clean.contains('T') && clean.length >= 15) {
        final timePart = clean.substring(clean.indexOf('T') + 1);
        if (timePart.length >= 6) {
          h = int.tryParse(timePart.substring(0, 2)) ?? 0;
          min = int.tryParse(timePart.substring(2, 4)) ?? 0;
          sec = int.tryParse(timePart.substring(4, 6)) ?? 0;
        }
      }
      return DateTime.utc(y, m, d, h, min, sec);
    }
    return null;
  }

  static EmailPayload _parseEmail(String raw) {
    if (raw.toLowerCase().startsWith('matmsg:')) {
      final body = raw.substring(7);
      final segments = _splitEscaped(body, ';');
      String to = '';
      String? sub;
      String? msgBody;

      for (final s in segments) {
        final colon = s.indexOf(':');
        if (colon == -1) continue;
        final k = s.substring(0, colon).toUpperCase();
        final v = s.substring(colon + 1);
        if (k == 'TO') to = v;
        if (k == 'SUB') sub = v;
        if (k == 'BODY') msgBody = v;
      }
      return EmailPayload(to: to, subject: sub, body: msgBody);
    }

    final uri = Uri.parse(raw);
    return EmailPayload(
      to: uri.path,
      subject: uri.queryParameters['subject'],
      body: uri.queryParameters['body'],
      cc: uri.queryParameters['cc'],
    );
  }

  static SmsPayload _parseSms(String raw) {
    if (raw.toLowerCase().startsWith('smsto:')) {
      final rest = raw.substring(6);
      final colon = rest.indexOf(':');
      if (colon != -1) {
        final phone = rest.substring(0, colon);
        final msg = rest.substring(colon + 1);
        return SmsPayload(phoneNumber: phone, message: msg);
      }
      return SmsPayload(phoneNumber: rest);
    }

    final uri = Uri.parse(raw);
    return SmsPayload(
      phoneNumber: uri.path,
      message: uri.queryParameters['body'],
    );
  }

  static TelPayload _parseTel(String raw) {
    return TelPayload(phoneNumber: raw.substring(4));
  }

  static OtpAuthPayload _parseOtpAuth(String raw) {
    final uri = Uri.parse(raw);
    final typeStr = uri.host.toLowerCase();
    final otpType = typeStr == 'hotp' ? OtpType.hotp : OtpType.totp;
    var label = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;

    String? issuer = uri.queryParameters['issuer'];
    String accountName = label;

    if (label.contains(':')) {
      final parts = label.split(':');
      issuer ??= Uri.decodeComponent(parts[0]);
      accountName = Uri.decodeComponent(parts.sublist(1).join(':'));
    } else {
      accountName = Uri.decodeComponent(label);
    }

    final secret = uri.queryParameters['secret'] ?? '';
    final algoStr = (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();
    final algorithm = algoStr == 'SHA256'
        ? OtpAlgorithm.sha256
        : algoStr == 'SHA512'
            ? OtpAlgorithm.sha512
            : OtpAlgorithm.sha1;
    final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;
    final counter = int.tryParse(uri.queryParameters['counter'] ?? '');

    return OtpAuthPayload(
      otpType: otpType,
      accountName: accountName,
      secret: secret,
      issuer: issuer,
      algorithm: algorithm,
      digits: digits,
      period: period,
      counter: counter,
    );
  }

  static UpiPaymentPayload _parseUpi(String raw) {
    final uri = Uri.parse(raw);
    final params = uri.queryParameters;
    final amount = double.tryParse(params['am'] ?? '');
    return UpiPaymentPayload(
      payeeVpa: params['pa'] ?? '',
      payeeName: params['pn'] ?? '',
      amount: amount,
      currency: params['cu'] ?? 'INR',
      transactionNote: params['tn'],
      merchantCode: params['mc'],
      transactionRef: params['tr'],
    );
  }

  static EpcPaymentPayload _parseEpc(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    final bic = lines.length > 4 ? lines[4].trim() : '';
    final name = lines.length > 5 ? lines[5].trim() : '';
    final iban = lines.length > 6 ? lines[6].trim() : '';
    final amtStr = lines.length > 7 ? lines[7].trim() : '';
    double? amt;
    if (amtStr.startsWith('EUR')) {
      amt = double.tryParse(amtStr.substring(3).trim());
    }
    final rem = lines.length > 9 ? lines[9].trim() : null;

    return EpcPaymentPayload(
      bic: bic,
      recipientName: name,
      iban: iban,
      amount: amt,
      remittanceInfo: rem,
    );
  }

  static CryptoPaymentPayload _parseCrypto(String raw) {
    final colonIdx = raw.indexOf(':');
    final scheme = raw.substring(0, colonIdx).toLowerCase();
    final rest = raw.substring(colonIdx + 1);

    CryptoCurrency currency;
    switch (scheme) {
      case 'bitcoin':
        currency = CryptoCurrency.bitcoin;
        break;
      case 'ethereum':
        currency = CryptoCurrency.ethereum;
        break;
      case 'solana':
        currency = CryptoCurrency.solana;
        break;
      case 'litecoin':
        currency = CryptoCurrency.litecoin;
        break;
      default:
        currency = CryptoCurrency.other;
    }

    String address = rest;
    String? amount;
    String? label;
    String? message;

    final qIdx = rest.indexOf('?');
    if (qIdx != -1) {
      address = rest.substring(0, qIdx);
      final query = Uri.splitQueryString(rest.substring(qIdx + 1));
      amount = query['amount'] ?? query['value'];
      label = query['label'];
      message = query['message'];
    }

    return CryptoPaymentPayload(
      currency: currency,
      address: address,
      amount: amount,
      label: label,
      message: message,
    );
  }

  static Gs1DigitalLinkPayload _parseGs1(String raw) {
    if (raw.toLowerCase().startsWith('http://') || raw.toLowerCase().startsWith('https://')) {
      final uri = Uri.parse(raw);
      final segments = uri.pathSegments;
      String gtin = '';
      String? serial;

      for (var i = 0; i < segments.length; i++) {
        if (segments[i] == '01' && i + 1 < segments.length) {
          gtin = segments[i + 1];
        } else if (segments[i] == '21' && i + 1 < segments.length) {
          serial = segments[i + 1];
        }
      }

      final batch = uri.queryParameters['10'];
      final exp = uri.queryParameters['17'];
      final additional = Map<String, String>.from(uri.queryParameters)
        ..remove('10')
        ..remove('17');

      return Gs1DigitalLinkPayload(
        gtin: gtin,
        serialNumber: serial,
        batchLot: batch,
        expiryDate: exp,
        additionalAis: additional,
      );
    }

    // AI Parenthesized format, e.g. (01)09520123456788(21)XYZ123
    final gtinMatch = RegExp(r'\(01\)(\d{8,14})').firstMatch(raw);
    final gtin = gtinMatch?.group(1) ?? raw;
    final serialMatch = RegExp(r'\(21\)([A-Za-z0-9]+)').firstMatch(raw);
    final batchMatch = RegExp(r'\(10\)([A-Za-z0-9]+)').firstMatch(raw);

    return Gs1DigitalLinkPayload(
      gtin: gtin,
      serialNumber: serialMatch?.group(1),
      batchLot: batchMatch?.group(1),
    );
  }

  static PlainTextPayload _parsePlainText(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return PlainTextPayload(text: raw, isJson: true, jsonData: decoded);
    } catch (_) {
      return PlainTextPayload(text: raw, isJson: false);
    }
  }

  static List<String> _splitEscaped(String input, String delimiter) {
    final result = <String>[];
    final current = StringBuffer();
    bool escaped = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (escaped) {
        current.write(char);
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == delimiter) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      result.add(current.toString());
    }
    return result;
  }
}
