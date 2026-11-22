import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';

/// Context-aware card displaying structured attributes and dedicated action buttons
/// across all 15 supported QR payload formats.
class PayloadActionCard extends StatelessWidget {
  final QrPayload payload;
  final bool isQuarantined;
  final bool isActionUnlocked;
  final void Function(String actionName, String details)? onActionExecuted;
  final void Function(String textToCopy)? onCopyRequested;

  const PayloadActionCard({
    super.key,
    required this.payload,
    this.isQuarantined = false,
    this.isActionUnlocked = false,
    this.onActionExecuted,
    this.onCopyRequested,
  });

  void _handleCopy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    onCopyRequested?.call(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: CyberColors.slateCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(CyberTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: CyberTokens.spacingMd),
          _buildPayloadContent(context),
          const SizedBox(height: CyberTokens.spacingMd),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final typeName = payload.type.name.toUpperCase();
    return Row(
      children: [
        Icon(_getPayloadIcon(payload.type), color: CyberColors.neonCyan, size: 20),
        const SizedBox(width: 8),
        Text(
          typeName,
          style: CyberTypography.monospace(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: CyberColors.neonCyan,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        CyberBadge(
          text: payload.type.name,
          type: CyberBadgeType.info,
          isPill: true,
        ),
      ],
    );
  }

  IconData _getPayloadIcon(QrPayloadType type) {
    switch (type) {
      case QrPayloadType.url:
        return Icons.language_rounded;
      case QrPayloadType.wifi:
        return Icons.wifi_rounded;
      case QrPayloadType.vcard:
      case QrPayloadType.mecard:
        return Icons.contact_page_rounded;
      case QrPayloadType.otpauth:
        return Icons.lock_clock_rounded;
      case QrPayloadType.upi:
      case QrPayloadType.epc:
      case QrPayloadType.crypto:
        return Icons.payment_rounded;
      case QrPayloadType.geo:
        return Icons.location_on_rounded;
      case QrPayloadType.email:
        return Icons.email_rounded;
      case QrPayloadType.sms:
        return Icons.sms_rounded;
      case QrPayloadType.tel:
        return Icons.phone_rounded;
      case QrPayloadType.event:
        return Icons.event_rounded;
      case QrPayloadType.gs1:
        return Icons.barcode_reader;
      case QrPayloadType.plainText:
        return Icons.text_snippet_rounded;
    }
  }

  Widget _buildPayloadContent(BuildContext context) {
    final p = payload;

    if (p is UrlPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('HOST', p.uri.host),
          _buildAttributeRow('SCHEME', p.uri.scheme.toUpperCase()),
          _buildAttributeRow('FULL URL', p.toRawPayload(), isMonospace: true),
        ],
      );
    } else if (p is WifiPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('SSID', p.ssid),
          _buildAttributeRow('AUTH', p.authType.name.toUpperCase()),
          _buildAttributeRow('PASSWORD', p.password.isNotEmpty ? '••••••••' : '(None)'),
          _buildAttributeRow('HIDDEN', p.isHidden ? 'Yes' : 'No'),
        ],
      );
    } else if (p is VCardPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('NAME', p.formattedName),
          if (p.phoneNumbers.isNotEmpty) _buildAttributeRow('PHONE', p.phoneNumbers.first),
          if (p.emails.isNotEmpty) _buildAttributeRow('EMAIL', p.emails.first),
          if (p.organization != null) _buildAttributeRow('ORG', p.organization!),
          if (p.title != null) _buildAttributeRow('TITLE', p.title!),
        ],
      );
    } else if (p is MeCardPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('NAME', p.name),
          if (p.telephone != null) _buildAttributeRow('PHONE', p.telephone!),
          if (p.email != null) _buildAttributeRow('EMAIL', p.email!),
          if (p.note != null) _buildAttributeRow('NOTE', p.note!),
        ],
      );
    } else if (p is OtpAuthPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('ACCOUNT', p.accountName),
          if (p.issuer != null) _buildAttributeRow('ISSUER', p.issuer!),
          _buildAttributeRow('TYPE', p.otpType.name.toUpperCase()),
          _buildAttributeRow('DIGITS', p.digits.toString()),
          _buildAttributeRow('ALGORITHM', p.algorithm.name.toUpperCase()),
        ],
      );
    } else if (p is UpiPaymentPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('PAYEE', p.payeeName),
          _buildAttributeRow('VPA', p.payeeVpa, isMonospace: true),
          if (p.amount != null) _buildAttributeRow('AMOUNT', '${p.currency} ${p.amount!.toStringAsFixed(2)}'),
          if (p.transactionNote != null) _buildAttributeRow('NOTE', p.transactionNote!),
        ],
      );
    } else if (p is EpcPaymentPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('RECIPIENT', p.recipientName),
          _buildAttributeRow('IBAN', p.iban, isMonospace: true),
          if (p.bic.isNotEmpty) _buildAttributeRow('BIC', p.bic),
          if (p.amount != null) _buildAttributeRow('AMOUNT', 'EUR ${p.amount!.toStringAsFixed(2)}'),
        ],
      );
    } else if (p is CryptoPaymentPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('COIN', p.currency.name.toUpperCase()),
          _buildAttributeRow('ADDRESS', p.address, isMonospace: true),
          if (p.amount != null) _buildAttributeRow('AMOUNT', '${p.amount} ${p.currency.name.toUpperCase()}'),
          if (p.label != null) _buildAttributeRow('LABEL', p.label!),
        ],
      );
    } else if (p is GeoPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('LATITUDE', p.latitude.toStringAsFixed(6)),
          _buildAttributeRow('LONGITUDE', p.longitude.toStringAsFixed(6)),
          if (p.altitude != null) _buildAttributeRow('ALTITUDE', '${p.altitude!.toStringAsFixed(2)} m'),
        ],
      );
    } else if (p is EmailPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('TO', p.to),
          if (p.subject != null) _buildAttributeRow('SUBJECT', p.subject!),
          if (p.body != null) _buildAttributeRow('BODY', p.body!),
        ],
      );
    } else if (p is SmsPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('NUMBER', p.phoneNumber),
          if (p.message != null) _buildAttributeRow('MESSAGE', p.message!),
        ],
      );
    } else if (p is TelPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('NUMBER', p.phoneNumber),
        ],
      );
    } else if (p is EventPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('SUMMARY', p.summary),
          if (p.location != null) _buildAttributeRow('LOCATION', p.location!),
          _buildAttributeRow('START', p.dtStart.toIso8601String()),
          if (p.dtEnd != null) _buildAttributeRow('END', p.dtEnd!.toIso8601String()),
        ],
      );
    } else if (p is Gs1DigitalLinkPayload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('GTIN', p.gtin),
          if (p.serialNumber != null) _buildAttributeRow('SERIAL', p.serialNumber!),
          if (p.batchLot != null) _buildAttributeRow('LOT', p.batchLot!),
          _buildAttributeRow('RAW GS1', p.toRawPayload(), isMonospace: true),
        ],
      );
    } else {
      // PlainTextPayload & fallback
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttributeRow('CONTENT', p.toRawPayload(), isMonospace: true),
        ],
      );
    }
  }

  Widget _buildAttributeRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: CyberTypography.monospace(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CyberColors.textMutedDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? CyberTypography.monospace(fontSize: 12, color: CyberColors.textPrimaryDark)
                  : const TextStyle(fontSize: 13, color: CyberColors.textPrimaryDark),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final canExecuteDangerous = !isQuarantined || isActionUnlocked;
    final p = payload;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (p is UrlPayload) ...[
          CyberButton(
            label: canExecuteDangerous ? 'Open Safe Link' : 'Link Quarantined',
            icon: Icons.open_in_new_rounded,
            variant: canExecuteDangerous ? CyberButtonVariant.primary : CyberButtonVariant.secondary,
            onPressed: canExecuteDangerous
                ? () => onActionExecuted?.call('open_url', p.toRawPayload())
                : null,
          ),
          CyberButton(
            label: 'Copy URL',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.toRawPayload(), 'URL'),
          ),
        ] else if (p is WifiPayload) ...[
          CyberButton(
            label: canExecuteDangerous ? 'Connect Network' : 'Network Quarantined',
            icon: Icons.wifi_protected_setup_rounded,
            variant: canExecuteDangerous ? CyberButtonVariant.primary : CyberButtonVariant.secondary,
            onPressed: canExecuteDangerous
                ? () => onActionExecuted?.call('connect_wifi', p.ssid)
                : null,
          ),
          if (p.password.isNotEmpty)
            CyberButton(
              label: 'Copy Password',
              icon: Icons.key_rounded,
              variant: CyberButtonVariant.outline,
              onPressed: () => _handleCopy(context, p.password, 'Wi-Fi Password'),
            ),
        ] else if (p is VCardPayload) ...[
          CyberButton(
            label: 'Save Contact',
            icon: Icons.person_add_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('save_contact', p.formattedName),
          ),
          CyberButton(
            label: 'Copy Details',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.toRawPayload(), 'Contact'),
          ),
        ] else if (p is MeCardPayload) ...[
          CyberButton(
            label: 'Save Contact',
            icon: Icons.person_add_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('save_contact', p.name),
          ),
          CyberButton(
            label: 'Copy Details',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.toRawPayload(), 'Contact'),
          ),
        ] else if (p is OtpAuthPayload) ...[
          CyberButton(
            label: 'Copy Code',
            icon: Icons.security_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => _handleCopy(context, p.secret, 'TOTP Secret'),
          ),
        ] else if (p is UpiPaymentPayload) ...[
          CyberButton(
            label: canExecuteDangerous ? 'Pay via UPI' : 'Payment Quarantined',
            icon: Icons.send_rounded,
            variant: canExecuteDangerous ? CyberButtonVariant.primary : CyberButtonVariant.secondary,
            onPressed: canExecuteDangerous
                ? () => onActionExecuted?.call('pay_upi', p.payeeVpa)
                : null,
          ),
          CyberButton(
            label: 'Copy VPA',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.payeeVpa, 'VPA'),
          ),
        ] else if (p is EpcPaymentPayload) ...[
          CyberButton(
            label: 'Copy IBAN',
            icon: Icons.credit_card_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => _handleCopy(context, p.iban, 'IBAN'),
          ),
        ] else if (p is CryptoPaymentPayload) ...[
          CyberButton(
            label: 'Copy Address',
            icon: Icons.currency_bitcoin_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => _handleCopy(context, p.address, 'Address'),
          ),
        ] else if (p is GeoPayload) ...[
          CyberButton(
            label: 'Open in Maps',
            icon: Icons.map_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('open_map', '${p.latitude},${p.longitude}'),
          ),
          CyberButton(
            label: 'Copy Coordinates',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, '${p.latitude}, ${p.longitude}', 'Coordinates'),
          ),
        ] else if (p is EmailPayload) ...[
          CyberButton(
            label: 'Compose Email',
            icon: Icons.email_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('compose_email', p.to),
          ),
          CyberButton(
            label: 'Copy Email',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.to, 'Email'),
          ),
        ] else if (p is SmsPayload) ...[
          CyberButton(
            label: 'Send SMS',
            icon: Icons.sms_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('send_sms', p.phoneNumber),
          ),
          CyberButton(
            label: 'Copy Number',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.phoneNumber, 'Phone Number'),
          ),
        ] else if (p is TelPayload) ...[
          CyberButton(
            label: 'Call',
            icon: Icons.phone_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('call_phone', p.phoneNumber),
          ),
          CyberButton(
            label: 'Copy Number',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.phoneNumber, 'Phone Number'),
          ),
        ] else if (p is EventPayload) ...[
          CyberButton(
            label: 'Add Event',
            icon: Icons.event_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('add_event', p.summary),
          ),
          CyberButton(
            label: 'Copy Details',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.toRawPayload(), 'Event Details'),
          ),
        ] else if (p is Gs1DigitalLinkPayload) ...[
          CyberButton(
            label: 'Lookup GS1',
            icon: Icons.qr_code_2_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => onActionExecuted?.call('lookup_gs1', p.gtin),
          ),
          CyberButton(
            label: 'Copy GTIN',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.outline,
            onPressed: () => _handleCopy(context, p.gtin, 'GTIN'),
          ),
        ] else ...[
          CyberButton(
            label: 'Copy Content',
            icon: Icons.copy_rounded,
            variant: CyberButtonVariant.primary,
            onPressed: () => _handleCopy(context, p.toRawPayload(), 'Content'),
          ),
        ],
      ],
    );
  }
}
