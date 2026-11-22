/// Enumerations for the Universal QR Ecosystem.
library qr_enums;

/// Supported structured QR payload formats (15 distinct types).
enum QrPayloadType {
  url,
  wifi,
  vcard,
  mecard,
  geo,
  event,
  email,
  sms,
  tel,
  otpauth,
  upi,
  epc,
  crypto,
  gs1,
  plainText,
}

/// Security risk classification levels determined by Threat Firewall.
enum SecurityThreatLevel {
  safe,
  caution,
  suspicious,
  critical,
}

/// Role classification for RBAC and cryptographic entitlements.
enum UserRole {
  user,
  admin,
}

/// Wi-Fi authentication types.
enum WifiAuthType {
  wpa,
  wpa2,
  wpa3,
  wep,
  none,
}

/// OTP / 2FA algorithm types.
enum OtpAlgorithm {
  sha1,
  sha256,
  sha512,
}

/// OTP token type.
enum OtpType {
  totp,
  hotp,
}

/// Supported cryptocurrency schemes.
enum CryptoCurrency {
  bitcoin,
  ethereum,
  solana,
  litecoin,
  other,
}

/// Origin of a stored QR code item in the vault.
enum QrItemOrigin {
  scanned,
  generated,
}

/// Sorting criteria for querying the vault.
enum QrVaultSortBy {
  createdAtDesc,
  createdAtAsc,
  titleAsc,
  safetyScoreAsc,
  safetyScoreDesc,
}
