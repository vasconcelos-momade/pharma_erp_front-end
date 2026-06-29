import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class PharmaHealthcareTokens extends ThemeExtension<PharmaHealthcareTokens> {
  const PharmaHealthcareTokens({
    required this.prescription,
    required this.dispensed,
    required this.controlledMedicine,
    required this.batch,
    required this.expiry,
    required this.expired,
    required this.coldChain,
    required this.inventory,
    required this.quarantine,
    required this.recall,
    required this.incineration,
    required this.temperatureAlert,
  });

  final Color prescription;
  final Color dispensed;
  final Color controlledMedicine;
  final Color batch;
  final Color expiry;
  final Color expired;
  final Color coldChain;
  final Color inventory;
  final Color quarantine;
  final Color recall;
  final Color incineration;
  final Color temperatureAlert;

  factory PharmaHealthcareTokens.fromLegacy(PharmaTokens tokens) {
    return PharmaHealthcareTokens(
      prescription: tokens.brandBlue,
      dispensed: tokens.posSuccess,
      controlledMedicine: tokens.psychotropic,
      batch: tokens.brandBlueHover,
      expiry: tokens.posWarning,
      expired: tokens.posDanger,
      coldChain: tokens.posInfo,
      inventory: tokens.brandGreen,
      quarantine: tokens.quarantine,
      recall: tokens.recall,
      incineration: tokens.incineration,
      temperatureAlert: tokens.posWarning,
    );
  }

  @override
  PharmaHealthcareTokens copyWith({
    Color? prescription,
    Color? dispensed,
    Color? controlledMedicine,
    Color? batch,
    Color? expiry,
    Color? expired,
    Color? coldChain,
    Color? inventory,
    Color? quarantine,
    Color? recall,
    Color? incineration,
    Color? temperatureAlert,
  }) {
    return PharmaHealthcareTokens(
      prescription: prescription ?? this.prescription,
      dispensed: dispensed ?? this.dispensed,
      controlledMedicine: controlledMedicine ?? this.controlledMedicine,
      batch: batch ?? this.batch,
      expiry: expiry ?? this.expiry,
      expired: expired ?? this.expired,
      coldChain: coldChain ?? this.coldChain,
      inventory: inventory ?? this.inventory,
      quarantine: quarantine ?? this.quarantine,
      recall: recall ?? this.recall,
      incineration: incineration ?? this.incineration,
      temperatureAlert: temperatureAlert ?? this.temperatureAlert,
    );
  }

  @override
  PharmaHealthcareTokens lerp(
    ThemeExtension<PharmaHealthcareTokens>? other,
    double t,
  ) {
    if (other is! PharmaHealthcareTokens) return this;
    return PharmaHealthcareTokens(
      prescription: Color.lerp(prescription, other.prescription, t)!,
      dispensed: Color.lerp(dispensed, other.dispensed, t)!,
      controlledMedicine:
          Color.lerp(controlledMedicine, other.controlledMedicine, t)!,
      batch: Color.lerp(batch, other.batch, t)!,
      expiry: Color.lerp(expiry, other.expiry, t)!,
      expired: Color.lerp(expired, other.expired, t)!,
      coldChain: Color.lerp(coldChain, other.coldChain, t)!,
      inventory: Color.lerp(inventory, other.inventory, t)!,
      quarantine: Color.lerp(quarantine, other.quarantine, t)!,
      recall: Color.lerp(recall, other.recall, t)!,
      incineration: Color.lerp(incineration, other.incineration, t)!,
      temperatureAlert:
          Color.lerp(temperatureAlert, other.temperatureAlert, t)!,
    );
  }
}

extension PharmaHealthcareTokensX on BuildContext {
  PharmaHealthcareTokens get healthcareTokens =>
      Theme.of(this).extension<PharmaHealthcareTokens>() ??
      PharmaHealthcareTokens.fromLegacy(pharmaTokens);
}

