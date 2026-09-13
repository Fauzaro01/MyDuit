import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/financial_calculator_service.dart';

void main() {
  group('FinancialCalculatorService Tests', () {
    test('calculateCompoundInterest calculates correctly', () {
      final res = FinancialCalculatorService.calculateCompoundInterest(
        initialDeposit: 10000000,
        monthlyDeposit: 1000000,
        annualInterestRatePercent: 12,
        years: 5,
      );

      expect(res.futureValue, greaterThan(10000000 + 1000000 * 60));
      expect(res.totalPrincipal, 10000000 + 1000000 * 60);
      expect(res.totalInterest, greaterThan(0));
      expect(res.yearlyBreakdown.length, 5);
      expect(res.yearlyBreakdown.first.year, 1);
    });

    test('calculateLoan calculates monthly annuity correctly', () {
      final res = FinancialCalculatorService.calculateLoan(
        principal: 120000000,
        annualInterestRatePercent: 12,
        tenureMonths: 12,
      );

      expect(res.monthlyPayment, greaterThan(10000000));
      expect(res.totalPayment, greaterThan(120000000));
      expect(res.totalInterest, greaterThan(0));
    });

    test('calculateEmergencyFund calculates based on risk profile', () {
      final singleRes = FinancialCalculatorService.calculateEmergencyFund(
        monthlyExpense: 5000000,
        isMarried: false,
        dependentsCount: 0,
        isFreelancer: false,
      );
      expect(singleRes.recommendedMonths, 3);
      expect(singleRes.targetAmount, 15000000);

      final familyRes = FinancialCalculatorService.calculateEmergencyFund(
        monthlyExpense: 5000000,
        isMarried: true,
        dependentsCount: 2,
        isFreelancer: true,
      );
      expect(familyRes.recommendedMonths, 12); // clamped at 12
      expect(familyRes.targetAmount, 60000000);
    });

    test('calculateRetirement calculates 4 percent rule nest egg', () {
      final res = FinancialCalculatorService.calculateRetirement(
        currentMonthlyExpense: 10000000,
        currentAge: 30,
        targetRetirementAge: 55,
        currentSavings: 100000000,
        expectedAnnualReturnPercent: 8,
      );

      // Target = 10jt * 12 * 25 = 3M
      expect(res.targetNestEgg, 3000000000);
      expect(res.yearsToRetirement, 25);
      expect(res.monthlySavingsNeeded, greaterThan(0));
    });
  });
}
