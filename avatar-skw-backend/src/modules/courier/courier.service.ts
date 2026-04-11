import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  CourierRule,
  CourierRuleType,
} from './entities/courier-rule.entity';
import { SettingsService } from '../settings/settings.service';

@Injectable()
export class CourierService {
  constructor(
    @InjectRepository(CourierRule)
    private courierRuleRepository: Repository<CourierRule>,
    private settingsService: SettingsService,
  ) {}

  /**
   * Calculate courier fee based on order value and optional weight/address
   * Returns fee in paise
   * Rules are applied in priority order (lower priority number = higher priority)
   * First matching rule wins
   * If no rule matches, returns 0 paise (free shipping)
   */
  async calculateFee(
    orderValuePaise: number,
    weight?: number,
    address?: any,
  ): Promise<number> {
    const activeRules = await this.courierRuleRepository.find({
      where: { active: true },
      order: { priority: 'ASC' },
    });

    for (const rule of activeRules) {
      if (this.ruleMatches(rule, orderValuePaise, weight, address)) {
        return this.calculateRuleFee(rule, orderValuePaise, weight);
      }
    }

    // No rule matched — fall back to standard shipping charge from settings
    try {
      const { standardShippingPaise } = await this.settingsService.getCartSettings();
      return standardShippingPaise;
    } catch {
      return 0;
    }
  }

  private ruleMatches(
    rule: CourierRule,
    orderValuePaise: number,
    weight?: number,
    address?: any,
  ): boolean {
    switch (rule.ruleType) {
      case CourierRuleType.FLAT:
        return true; // Flat fee applies to all orders

      case CourierRuleType.VALUE_SLAB:
        const orderValue = orderValuePaise / 100; // Convert to ₹
        return rule.ranges.some(
          (range) =>
            (!range.min || orderValue >= range.min) &&
            (!range.max || orderValue <= range.max),
        );

      case CourierRuleType.WEIGHT_SLAB:
        if (!weight) return false;
        return rule.ranges.some(
          (range) =>
            (!range.min || weight >= range.min) &&
            (!range.max || weight <= range.max),
        );

      default:
        return false;
    }
  }

  private calculateRuleFee(
    rule: CourierRule,
    orderValuePaise: number,
    weight?: number,
  ): number {
    switch (rule.ruleType) {
      case CourierRuleType.FLAT:
        return rule.flatFeePaise || 0;

      case CourierRuleType.VALUE_SLAB:
        const orderValue = orderValuePaise / 100;
        const matchingRange = rule.ranges.find(
          (range) =>
            (!range.min || orderValue >= range.min) &&
            (!range.max || orderValue <= range.max),
        );
        return matchingRange?.feePaise || 0;

      case CourierRuleType.WEIGHT_SLAB:
        if (!weight) return 0;
        const matchingWeightRange = rule.ranges.find(
          (range) =>
            (!range.min || weight >= range.min) &&
            (!range.max || weight <= range.max),
        );
        return matchingWeightRange?.feePaise || 0;

      default:
        return 0;
    }
  }
}


