import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from './entities/setting.entity';
import { CreateSettingDto, UpdateSettingDto } from './dto/settings.dto';

@Injectable()
export class SettingsService {
  // Whitelist of public settings keys (not secret)
  private readonly publicKeys = [
    'whatsapp.business_number',
    'whatsapp.integration_mode',
    'whatsapp.template_id', // Legacy/Default
    // Credentials (Publicly explicitly listed here for Admin UI fetch, though secrets are usually hidden)
    'whatsapp.phone_id',
    'whatsapp.access_token',
    // Templates

    'whatsapp.template.otp.name', 'whatsapp.template.otp.lang', 'whatsapp.template.otp.enabled',
    'whatsapp.template.user_reg.name', 'whatsapp.template.user_reg.lang', 'whatsapp.template.user_reg.enabled',
    'whatsapp.template.dealer_reg.name', 'whatsapp.template.dealer_reg.lang', 'whatsapp.template.dealer_reg.enabled',
    'whatsapp.template.dealer_approved.name', 'whatsapp.template.dealer_approved.lang', 'whatsapp.template.dealer_approved.enabled',
    'whatsapp.template.dealer_rejected.name', 'whatsapp.template.dealer_rejected.lang', 'whatsapp.template.dealer_rejected.enabled',
    'whatsapp.template.order_placed.name', 'whatsapp.template.order_placed.lang', 'whatsapp.template.order_placed.enabled',
    'whatsapp.template.order_status.name', 'whatsapp.template.order_status.lang', 'whatsapp.template.order_status.enabled',
    'whatsapp.template.abandoned_cart.name', 'whatsapp.template.abandoned_cart.lang', 'whatsapp.template.abandoned_cart.enabled',

    'branding.company_name',
    'tax.notes',
    'courier.default_rule',
    'system.maintenance_mode',
    'system.min_order_value',
    'system.shipping_charge',
  ];

  constructor(
    @InjectRepository(Setting)
    private settingRepository: Repository<Setting>,
  ) { }

  async getSetting(key: string): Promise<string | null> {
    const setting = await this.settingRepository.findOne({ where: { key } });
    return setting?.value || null;
  }

  /** Returns cart-level settings as plain numbers for use in business logic. */
  async getCartSettings(): Promise<{ minOrderValuePaise: number; standardShippingPaise: number }> {
    const [minVal, shippingVal] = await Promise.all([
      this.getSetting('system.min_order_value'),
      this.getSetting('system.shipping_charge'),
    ]);
    const minOrderValuePaise = Math.round((parseFloat(minVal ?? '0') || 0) * 100);
    const standardShippingPaise = Math.round((parseFloat(shippingVal ?? '0') || 0) * 100);
    return { minOrderValuePaise, standardShippingPaise };
  }

  async getPublicSettings() {
    const settings = await this.settingRepository.find({
      where: { isSecret: false },
    });

    // Also filter by whitelist for extra security
    return settings
      .filter((s) => this.publicKeys.includes(s.key))
      .map((s) => ({
        key: s.key,
        value: s.value,
      }));
  }

  async getSettingByKey(key: string) {
    const setting = await this.settingRepository.findOne({ where: { key } });

    if (!setting) {
      throw new NotFoundException(`Setting ${key} not found`);
    }

    // Never return secret settings
    if (setting.isSecret) {
      throw new NotFoundException(`Setting ${key} not found`);
    }

    // Check whitelist
    if (!this.publicKeys.includes(key)) {
      throw new NotFoundException(`Setting ${key} not found`);
    }

    return {
      key: setting.key,
      value: setting.value,
    };
  }

  async createOrUpdate(createDto: CreateSettingDto) {
    // Prevent creating secret settings via API
    if (createDto.isSecret) {
      throw new Error('Cannot create secret settings via API');
    }

    let setting = await this.settingRepository.findOne({
      where: { key: createDto.key },
    });

    if (setting) {
      setting.value = createDto.value;
      setting.isSecret = false; // Ensure it's not secret
    } else {
      setting = this.settingRepository.create({
        key: createDto.key,
        value: createDto.value,
        isSecret: false,
      });
    }

    return this.settingRepository.save(setting);
  }

  async update(key: string, updateDto: UpdateSettingDto) {
    const setting = await this.settingRepository.findOne({ where: { key } });

    if (!setting) {
      throw new NotFoundException(`Setting ${key} not found`);
    }

    // We allow updating secrets via API because the Controller is guarded by Admin Role
    // if (setting.isSecret) {
    //   throw new Error('Cannot update secret settings via API');
    // }

    setting.value = updateDto.value;
    return this.settingRepository.save(setting);
  }
}


