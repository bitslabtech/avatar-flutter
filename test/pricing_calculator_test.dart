import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/core/utils/pricing_calculator.dart';

void main() {
  group('PricingCalculator Tests', () {
    test('Calculates purchase cost, margin, GST, net sales, and dealer price accurately', () {
      // Direct Costs: Product 100, Box 10, Handling 10 => Purchase Cost = 120
      // Margin 25% of 120 = 30 => Base = 150
      // GST 18% of 150 = 27 => Net Sales Price = 177
      // Net DP 25% markup on 177 = 44.25 => Net DP = 221.25
      // Rounded Net DP = 221.0
      final result = PricingCalculator.calculate(
        productCost: 100.0,
        boxCost: 10.0,
        handlingFee: 10.0,
        marginPercent: 25.0,
        gstPercent: 18.0,
        roundOffNetSales: true,
        dpPercent: 25.0,
        roundOffNetDp: true,
      );

      expect(result.purchaseCost, equals(120.0));
      expect(result.marginAmount, equals(30.0));
      expect(result.priceAfterMargin, equals(150.0));
      expect(result.gstAmount, equals(27.0));
      expect(result.netSalesPrice, equals(177.0));
      expect(result.effectiveNetSalesPrice, equals(177.0));
      expect(result.netDpAmount, equals(44.25));
      expect(result.netDp, equals(221.25));
      expect(result.effectiveNetDp, equals(221.0));
    });

    test('Tests GST Slabs: 5%, 12%, 18%, 28%', () {
      const baseCost = 200.0; // 180 + 10 + 10
      // Margin 25% of 200 = 50 => Price after margin = 250

      final slab5 = PricingCalculator.calculate(
        productCost: 180, boxCost: 10, handlingFee: 10,
        marginPercent: 25, gstPercent: 5,
      );
      expect(slab5.purchaseCost, equals(baseCost));
      expect(slab5.gstAmount, equals(250.0 * 0.05)); // 12.5

      final slab12 = PricingCalculator.calculate(
        productCost: 180, boxCost: 10, handlingFee: 10,
        marginPercent: 25, gstPercent: 12,
      );
      expect(slab12.gstAmount, equals(250.0 * 0.12)); // 30.0

      final slab18 = PricingCalculator.calculate(
        productCost: 180, boxCost: 10, handlingFee: 10,
        marginPercent: 25, gstPercent: 18,
      );
      expect(slab18.gstAmount, equals(250.0 * 0.18)); // 45.0

      final slab28 = PricingCalculator.calculate(
        productCost: 180, boxCost: 10, handlingFee: 10,
        marginPercent: 25, gstPercent: 28,
      );
      expect(slab28.gstAmount, equals(250.0 * 0.28)); // 70.0
    });

    test('Editable Margin % and DP % correctly alters computed amounts', () {
      final custom = PricingCalculator.calculate(
        productCost: 1000.0,
        boxCost: 50.0,
        handlingFee: 50.0,
        marginPercent: 30.0, // custom margin
        gstPercent: 18.0,
        roundOffNetSales: false,
        dpPercent: 20.0, // custom DP
        roundOffNetDp: false,
      );

      // Purchase Cost = 1100
      expect(custom.purchaseCost, equals(1100.0));
      // Margin = 30% of 1100 = 330
      expect(custom.marginAmount, equals(330.0));
      // Base = 1430
      expect(custom.priceAfterMargin, equals(1430.0));
      // GST 18% of 1430 = 257.4
      expect(custom.gstAmount, closeTo(257.4, 0.001));
      // Net Sales = 1430 + 257.4 = 1687.4
      expect(custom.netSalesPrice, closeTo(1687.4, 0.001));
      expect(custom.effectiveNetSalesPrice, closeTo(1687.4, 0.001));
      // DP 20% on 1687.4 = 337.48 => Net DP = 2024.88
      expect(custom.netDpAmount, closeTo(337.48, 0.001));
      expect(custom.effectiveNetDp, closeTo(2024.88, 0.001));
    });

    test('Round off toggle operates as expected on both Net Sales and DP', () {
      // 100 + 3 + 1 = 104
      // Margin 25% = 26 => Base = 130
      // GST 18% = 23.4 => Net Sales = 153.4
      final withRoundOff = PricingCalculator.calculate(
        productCost: 100, boxCost: 3, handlingFee: 1,
        marginPercent: 25, gstPercent: 18,
        roundOffNetSales: true,
        dpPercent: 25,
        roundOffNetDp: true,
      );
      expect(withRoundOff.netSalesPrice, closeTo(153.4, 0.01));
      expect(withRoundOff.effectiveNetSalesPrice, equals(153.0)); // rounded from 153.4
      // DP on 153: 153 + 25% of 153 (38.25) = 191.25 => rounded to 191
      expect(withRoundOff.effectiveNetDp, equals(191.0));

      final withoutRoundOff = PricingCalculator.calculate(
        productCost: 100, boxCost: 3, handlingFee: 1,
        marginPercent: 25, gstPercent: 18,
        roundOffNetSales: false,
        dpPercent: 25,
        roundOffNetDp: false,
      );
      expect(withoutRoundOff.effectiveNetSalesPrice, closeTo(153.4, 0.01));
      // DP on 153.4: 153.4 * 1.25 = 191.75
      expect(withoutRoundOff.effectiveNetDp, closeTo(191.75, 0.01));
    });

    test('Zero costs edge cases', () {
      final zeroResult = PricingCalculator.calculate(
        productCost: 0,
        boxCost: 0,
        handlingFee: 0,
      );
      expect(zeroResult.purchaseCost, equals(0.0));
      expect(zeroResult.marginAmount, equals(0.0));
      expect(zeroResult.priceAfterMargin, equals(0.0));
      expect(zeroResult.gstAmount, equals(0.0));
      expect(zeroResult.effectiveNetSalesPrice, equals(0.0));
      expect(zeroResult.effectiveNetDp, equals(0.0));
    });

    test('toJson serializes all fields for storage in specifications', () {
      final res = PricingCalculator.calculate(
        productCost: 500, boxCost: 20, handlingFee: 30,
      );
      final json = res.toJson();
      expect(json['productCost'], equals(500.0));
      expect(json['purchaseCost'], equals(550.0));
      expect(json['dealerPrice'], equals(res.effectiveNetDp));
      expect(json.containsKey('roundOffNetSales'), isTrue);
      expect(json.containsKey('roundOffNetDp'), isTrue);
    });
  });
}
