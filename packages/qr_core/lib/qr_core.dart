/// Universal QR Core Library
///
/// Contains shared domain models, 15+ payload parsers, encoders, schema validators,
/// Ed25519 TrustQR cryptography, and asymmetric entitlement tokens.
library qr_core;

export 'src/models/qr_enums.dart';
export 'src/models/qr_item.dart';
export 'src/models/qr_payload.dart';
export 'src/validators/schema_validator.dart';
export 'src/parsers/qr_payload_parser.dart';
export 'src/crypto/crypto_keys.dart';
export 'src/crypto/ed25519_engine.dart';
export 'src/crypto/hmac_engine.dart';
export 'src/crypto/trust_qr_envelope.dart';
export 'src/crypto/entitlement_token.dart';
export 'src/vault/qr_vault_item.dart';
export 'src/vault/qr_collection.dart';
export 'src/vault/qr_vault_filter.dart';
export 'src/vault/vault_privacy_policy.dart';
export 'src/vault/vault_storage_adapter.dart';
export 'src/vault/in_memory_vault_storage_adapter.dart';
export 'src/vault/file_json_vault_storage_adapter.dart';
export 'src/vault/qr_vault.dart';
