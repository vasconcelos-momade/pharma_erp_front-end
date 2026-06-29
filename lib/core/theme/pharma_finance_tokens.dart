import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class PharmaFinanceTokens extends ThemeExtension<PharmaFinanceTokens> {
  const PharmaFinanceTokens({
    required this.income,
    required this.expense,
    required this.profit,
    required this.cash,
    required this.invoice,
    required this.paymentPending,
  });

  final Color income;
  final Color expense;
  final Color profit;
  final Color cash;
  final Color invoice;
  final Color paymentPending;

  factory PharmaFinanceTokens.fromLegacy(PharmaTokens tokens) {
    return PharmaFinanceTokens(
      income: tokens.posSuccess,
      expense: tokens.posDanger,
      profit: tokens.brandGreen,
      cash: tokens.brandBlue,
      invoice: tokens.brandBlueHover,
      paymentPending: tokens.posWarning,
    );
  }

  @override
  PharmaFinanceTokens copyWith({
    Color? income,
    Color? expense,
    Color? profit,
    Color? cash,
    Color? invoice,
    Color? paymentPending,
  }) {
    return PharmaFinanceTokens(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      cash: cash ?? this.cash,
      invoice: invoice ?? this.invoice,
      paymentPending: paymentPending ?? this.paymentPending,
    );
  }

  @override
  PharmaFinanceTokens lerp(ThemeExtension<PharmaFinanceTokens>? other, double t) {
    if (other is! PharmaFinanceTokens) return this;
    return PharmaFinanceTokens(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      cash: Color.lerp(cash, other.cash, t)!,
      invoice: Color.lerp(invoice, other.invoice, t)!,
      paymentPending: Color.lerp(paymentPending, other.paymentPending, t)!,
    );
  }
}

extension PharmaFinanceTokensX on BuildContext {
  PharmaFinanceTokens get financeTokens =>
      Theme.of(this).extension<PharmaFinanceTokens>() ??
      PharmaFinanceTokens.fromLegacy(pharmaTokens);
}

