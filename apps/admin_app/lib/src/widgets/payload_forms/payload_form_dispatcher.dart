import 'package:flutter/material.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_design_system/qr_design_system.dart';
import '../../state/studio_controller.dart';

/// Form dispatcher rendering input controls for all 15 supported QR payload formats.
class PayloadFormDispatcher extends StatelessWidget {
  final StudioController controller;

  const PayloadFormDispatcher({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return CyberGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'QR Payload & Format',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberTokens.neonCyan,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Raw Override', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                      Switch(
                        value: controller.useManualRawPayload,
                        activeThumbColor: CyberTokens.neonCyan,
                        onChanged: (val) => controller.setUseManualRawPayload(val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Format Selector Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: QrPayloadType.values.map((type) {
                    final isSelected = controller.payloadType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type.name.toUpperCase()),
                        selected: isSelected,
                        selectedColor: CyberTokens.neonCyan.withAlpha(64),
                        backgroundColor: CyberTokens.slateCard,
                        labelStyle: TextStyle(
                          color: isSelected ? CyberTokens.neonCyan : CyberTokens.cyberTextPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        onSelected: (_) => controller.setPayloadType(type),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.useManualRawPayload) ...[
                TextFormField(
                  initialValue: controller.manualRawPayload,
                  key: const Key('manual_raw_payload_field'),
                  decoration: const InputDecoration(
                    labelText: 'Manual Raw Payload Content',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code, color: CyberTokens.neonCyan),
                  ),
                  maxLines: 3,
                  onChanged: (val) => controller.setManualRawPayload(val),
                ),
              ] else ...[
                _buildTypeSpecificForm(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSpecificForm(BuildContext context) {
    switch (controller.payloadType) {
      case QrPayloadType.url:
        return TextFormField(
          key: const Key('url_input_field'),
          initialValue: controller.urlAddress,
          decoration: const InputDecoration(
            labelText: 'Destination Web URL',
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link, color: CyberTokens.neonCyan),
          ),
          onChanged: (val) {
            controller.urlAddress = val;
            controller.recalculate();
          },
        );

      case QrPayloadType.wifi:
        return Column(
          children: [
            TextFormField(
              key: const Key('wifi_ssid_field'),
              initialValue: controller.wifiSsid,
              decoration: const InputDecoration(
                labelText: 'Network SSID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi, color: CyberTokens.neonCyan),
              ),
              onChanged: (val) {
                controller.wifiSsid = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('wifi_password_field'),
              initialValue: controller.wifiPassword,
              decoration: const InputDecoration(
                labelText: 'WPA/WPA2/WPA3 Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline, color: CyberTokens.neonCyan),
              ),
              onChanged: (val) {
                controller.wifiPassword = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<WifiAuthType>(
                    // ignore: deprecated_member_use
                    value: controller.wifiAuth,
                    decoration: const InputDecoration(
                      labelText: 'Auth Security',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: CyberTokens.slateCard,
                    items: WifiAuthType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.wifiAuth = val;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Hidden SSID', style: TextStyle(color: CyberTokens.cyberTextPrimary)),
                    Checkbox(
                      value: controller.wifiIsHidden,
                      activeColor: CyberTokens.neonCyan,
                      onChanged: (val) {
                        controller.wifiIsHidden = val ?? false;
                        controller.recalculate();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.vcard:
        return Column(
          children: [
            TextFormField(
              key: const Key('vcard_fn_field'),
              initialValue: controller.vcardFormattedName,
              decoration: const InputDecoration(labelText: 'Formatted Name (FN)', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.vcardFormattedName = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('vcard_org_field'),
                    initialValue: controller.vcardOrg,
                    decoration: const InputDecoration(labelText: 'Organization', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.vcardOrg = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('vcard_title_field'),
                    initialValue: controller.vcardTitle,
                    decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.vcardTitle = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('vcard_phone_field'),
                    initialValue: controller.vcardPhone,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.vcardPhone = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('vcard_email_field'),
                    initialValue: controller.vcardEmail,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.vcardEmail = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.mecard:
        return Column(
          children: [
            TextFormField(
              key: const Key('mecard_name_field'),
              initialValue: controller.mecardName,
              decoration: const InputDecoration(labelText: 'Contact Name (LastName,FirstName)', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.mecardName = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('mecard_phone_field'),
                    initialValue: controller.mecardPhone,
                    decoration: const InputDecoration(labelText: 'Telephone', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.mecardPhone = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('mecard_email_field'),
                    initialValue: controller.mecardEmail,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.mecardEmail = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.geo:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('geo_lat_field'),
                    initialValue: controller.geoLat.toString(),
                    decoration: const InputDecoration(labelText: 'Latitude (-90 to +90)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        controller.geoLat = parsed;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('geo_lng_field'),
                    initialValue: controller.geoLng.toString(),
                    decoration: const InputDecoration(labelText: 'Longitude (-180 to +180)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        controller.geoLng = parsed;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('geo_query_field'),
              initialValue: controller.geoQuery,
              decoration: const InputDecoration(labelText: 'Query / Location Label', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.geoQuery = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.event:
        return Column(
          children: [
            TextFormField(
              key: const Key('event_summary_field'),
              initialValue: controller.eventSummary,
              decoration: const InputDecoration(labelText: 'Event Summary / Title', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.eventSummary = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('event_location_field'),
                    initialValue: controller.eventLocation,
                    decoration: const InputDecoration(labelText: 'Location / Venue', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.eventLocation = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event_desc_field'),
              initialValue: controller.eventDescription,
              decoration: const InputDecoration(labelText: 'Event Description', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.eventDescription = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.email:
        return Column(
          children: [
            TextFormField(
              key: const Key('email_to_field'),
              initialValue: controller.emailTo,
              decoration: const InputDecoration(labelText: 'Recipient Email', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.emailTo = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('email_subject_field'),
              initialValue: controller.emailSubject,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.emailSubject = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('email_body_field'),
              initialValue: controller.emailBody,
              decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder()),
              maxLines: 2,
              onChanged: (val) {
                controller.emailBody = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.sms:
        return Column(
          children: [
            TextFormField(
              key: const Key('sms_phone_field'),
              initialValue: controller.smsPhone,
              decoration: const InputDecoration(labelText: 'Recipient Phone Number', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.smsPhone = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('sms_msg_field'),
              initialValue: controller.smsMessage,
              decoration: const InputDecoration(labelText: 'SMS Text Message', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.smsMessage = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.tel:
        return TextFormField(
          key: const Key('tel_phone_field'),
          initialValue: controller.telPhone,
          decoration: const InputDecoration(labelText: 'Telephone Number', border: OutlineInputBorder()),
          onChanged: (val) {
            controller.telPhone = val;
            controller.recalculate();
          },
        );

      case QrPayloadType.otpauth:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('otp_account_field'),
                    initialValue: controller.otpAccount,
                    decoration: const InputDecoration(labelText: 'Account / User', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.otpAccount = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('otp_issuer_field'),
                    initialValue: controller.otpIssuer,
                    decoration: const InputDecoration(labelText: 'Issuer / Organization', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.otpIssuer = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('otp_secret_field'),
              initialValue: controller.otpSecret,
              decoration: const InputDecoration(labelText: 'Base32 Shared Secret', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.otpSecret = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.upi:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('upi_vpa_field'),
                    initialValue: controller.upiVpa,
                    decoration: const InputDecoration(labelText: 'Payee VPA (Virtual Payment Address)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.upiVpa = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('upi_payee_field'),
                    initialValue: controller.upiPayee,
                    decoration: const InputDecoration(labelText: 'Payee Legal Name', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.upiPayee = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('upi_amount_field'),
                    initialValue: controller.upiAmount.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        controller.upiAmount = parsed;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('upi_note_field'),
                    initialValue: controller.upiNote,
                    decoration: const InputDecoration(labelText: 'Transaction Note', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.upiNote = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.epc:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('epc_bic_field'),
                    initialValue: controller.epcBic,
                    decoration: const InputDecoration(labelText: 'Bank BIC / SWIFT', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.epcBic = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('epc_recipient_field'),
                    initialValue: controller.epcRecipient,
                    decoration: const InputDecoration(labelText: 'Recipient Name', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.epcRecipient = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('epc_iban_field'),
              initialValue: controller.epcIban,
              decoration: const InputDecoration(labelText: 'International IBAN', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.epcIban = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('epc_amount_field'),
                    initialValue: controller.epcAmount.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'EUR Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        controller.epcAmount = parsed;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('epc_remittance_field'),
                    initialValue: controller.epcRemittance,
                    decoration: const InputDecoration(labelText: 'Remittance Reference', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.epcRemittance = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.crypto:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CryptoCurrency>(
                    // ignore: deprecated_member_use
                    value: controller.cryptoCurrency,
                    decoration: const InputDecoration(labelText: 'Coin / Blockchain', border: OutlineInputBorder()),
                    dropdownColor: CyberTokens.slateCard,
                    items: CryptoCurrency.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.cryptoCurrency = val;
                        controller.recalculate();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('crypto_amount_field'),
                    initialValue: controller.cryptoAmount,
                    decoration: const InputDecoration(labelText: 'Amount (Optional)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.cryptoAmount = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('crypto_addr_field'),
              initialValue: controller.cryptoAddress,
              decoration: const InputDecoration(labelText: 'Recipient Wallet Address', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.cryptoAddress = val;
                controller.recalculate();
              },
            ),
          ],
        );

      case QrPayloadType.gs1:
        return Column(
          children: [
            TextFormField(
              key: const Key('gs1_gtin_field'),
              initialValue: controller.gs1Gtin,
              decoration: const InputDecoration(labelText: 'GTIN / Product Barcode (14 Digits)', border: OutlineInputBorder()),
              onChanged: (val) {
                controller.gs1Gtin = val;
                controller.recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('gs1_serial_field'),
                    initialValue: controller.gs1Serial,
                    decoration: const InputDecoration(labelText: 'Serial No. (AI 21)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.gs1Serial = val;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('gs1_batch_field'),
                    initialValue: controller.gs1Batch,
                    decoration: const InputDecoration(labelText: 'Batch / Lot (AI 10)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      controller.gs1Batch = val;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case QrPayloadType.plainText:
        return TextFormField(
          key: const Key('plaintext_field'),
          initialValue: controller.plainTextContent,
          decoration: const InputDecoration(labelText: 'Raw Plaintext / JSON Content', border: OutlineInputBorder()),
          maxLines: 3,
          onChanged: (val) {
            controller.plainTextContent = val;
            controller.recalculate();
          },
        );
    }
  }
}
