/// Pricing breakdown and calculation utility for Avatar product pricing engine.
class PricingBreakdown {
  final double productCost;
  final double boxCost;
  final double handlingFee;
  final double purchaseCost;
  final double marginPercent;
  final double marginAmount;
  final double priceAfterMargin;
  final double gstPercent;
  final double gstAmount;
  final double netSalesPrice;
  final bool roundOffNetSales;
  final double effectiveNetSalesPrice;
  final double dpPercent;
  final double netDpAmount;
  final double netDp;
  final bool roundOffNetDp;
  final double effectiveNetDp;

  const PricingBreakdown({
    required this.productCost,
    required this.boxCost,
    required this.handlingFee,
    required this.purchaseCost,
    required this.marginPercent,
    required this.marginAmount,
    required this.priceAfterMargin,
    required this.gstPercent,
    required this.gstAmount,
    required this.netSalesPrice,
    required this.roundOffNetSales,
    required this.effectiveNetSalesPrice,
    required this.dpPercent,
    required this.netDpAmount,
    required this.netDp,
    required this.roundOffNetDp,
    required this.effectiveNetDp,
  });

  Map<String, dynamic> toJson() => {
    'productCost': productCost,
    'boxCost': boxCost,
    'handlingFee': handlingFee,
    'purchaseCost': purchaseCost,
    'marginPercent': marginPercent,
    'marginAmount': marginAmount,
    'priceAfterMargin': priceAfterMargin,
    'gstPercent': gstPercent,
    'gstAmount': gstAmount,
    'netSalesPrice': netSalesPrice,
    'roundOffNetSales': roundOffNetSales,
    'netSalesPriceFinal': effectiveNetSalesPrice,
    'dpPercent': dpPercent,
    'netDp': netDp,
    'roundOffNetDp': roundOffNetDp,
    'dealerPrice': effectiveNetDp,
  };
}

class PricingCalculator {
  static PricingBreakdown calculate({
    required double productCost,
    required double boxCost,
    required double handlingFee,
    double marginPercent = 25.0,
    double gstPercent = 18.0,
    bool roundOffNetSales = true,
    double dpPercent = 25.0,
    bool roundOffNetDp = true,
  }) {
    final purchaseCost = productCost + boxCost + handlingFee;
    final marginAmount = purchaseCost * (marginPercent / 100.0);
    final priceAfterMargin = purchaseCost + marginAmount;
    final gstAmount = priceAfterMargin * (gstPercent / 100.0);
    final netSalesPrice = priceAfterMargin + gstAmount;
    final effectiveNetSalesPrice =
        roundOffNetSales ? netSalesPrice.roundToDouble() : netSalesPrice;
    final netDpAmount = effectiveNetSalesPrice * (dpPercent / 100.0);
    final netDp = effectiveNetSalesPrice + netDpAmount;
    final effectiveNetDp = roundOffNetDp ? netDp.roundToDouble() : netDp;

    return PricingBreakdown(
      productCost: productCost,
      boxCost: boxCost,
      handlingFee: handlingFee,
      purchaseCost: purchaseCost,
      marginPercent: marginPercent,
      marginAmount: marginAmount,
      priceAfterMargin: priceAfterMargin,
      gstPercent: gstPercent,
      gstAmount: gstAmount,
      netSalesPrice: netSalesPrice,
      roundOffNetSales: roundOffNetSales,
      effectiveNetSalesPrice: effectiveNetSalesPrice,
      dpPercent: dpPercent,
      netDpAmount: netDpAmount,
      netDp: netDp,
      roundOffNetDp: roundOffNetDp,
      effectiveNetDp: effectiveNetDp,
    );
  }
}
