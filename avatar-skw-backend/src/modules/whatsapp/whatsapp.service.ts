import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SettingsService } from '../settings/settings.service';
import { Order } from '../orders/entities/order.entity';
import { Quotation } from '../quotations/entities/quotation.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class WhatsAppService {
  constructor(
    private configService: ConfigService,
    private settingsService: SettingsService,
  ) { }

  async sendOtp(phone: string, otp: string): Promise<string> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.otp.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.otp.lang') || 'en_US';

      if (!templateName) {
        console.warn('WhatsApp OTP Template Name not configured');
        return 'Configuration Error';
      }

      return this.sendViaCloudAPI_Template(phone, templateName, langCode, [
        { type: 'body', parameters: [{ type: 'text', text: otp }] }
      ]);
    } else {
      // For testing/mock
      console.log(`[MOCK OTP] For ${phone}: ${otp}`);
      return 'Mock Sent';
    }
  }

  async sendOrderNotification(order: Order, user: User, isUpdate: boolean = false): Promise<string> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';
    const businessNumber =
      (await this.settingsService.getSetting('whatsapp.business_number')) ||
      '';

    if (integrationMode === 'cloud_api') {
      const templateKey = isUpdate ? 'whatsapp.template.order_status.name' : 'whatsapp.template.order_placed.name';
      const langKey = isUpdate ? 'whatsapp.template.order_status.lang' : 'whatsapp.template.order_placed.lang';

      const templateName = await this.settingsService.getSetting(templateKey);
      const langCode = await this.settingsService.getSetting(langKey) || 'en_US';

      if (!templateName) {
        // Fallback to legacy single template if specific not found
        const legacyTemplate = await this.settingsService.getSetting('whatsapp.template_id');
        if (legacyTemplate) {
          return this.sendViaCloudAPI_Template(user.phone, legacyTemplate, 'en_US', [
            { type: 'body', parameters: [{ type: 'text', text: user.name }, { type: 'text', text: order.orderNo }] }
          ]);
        }
        return this.buildDeepLink(order, businessNumber);
      }

      // Parameters depend on your template variables. Assuming generic 1: Name, 2: OrderNo, 3: Status
      const params = [
        {
          type: 'body', parameters: [
            { type: 'text', text: user.name },
            { type: 'text', text: order.orderNo },
            { type: 'text', text: isUpdate ? order.status : (order.grandTotalPaise / 100).toFixed(2) }
          ]
        }
      ];

      return this.sendViaCloudAPI_Template(user.phone, templateName, langCode, params);
    } else {
      return this.buildDeepLink(order, businessNumber);
    }
  }

  async sendQuotationNotification(
    quotation: Quotation,
    user: User,
  ): Promise<string> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    // ... Existing mock logic ...
    console.log('TODO: Implement Quotation Template Config');

    const businessNumber =
      (await this.settingsService.getSetting('whatsapp.business_number')) ||
      '';

    if (integrationMode === 'cloud_api') {
      // Fallback for now as quotation template wasn't explicitly requested
      return this.buildQuotationDeepLink(quotation, businessNumber);
    }

    return this.buildQuotationDeepLink(quotation, businessNumber);
  }

  async sendDealerApprovalNotification(user: User): Promise<void> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.dealer_approved.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.dealer_approved.lang') || 'en_US';

      if (templateName) {
        await this.sendViaCloudAPI_Template(user.phone, templateName, langCode, [
          { type: 'body', parameters: [{ type: 'text', text: user.name }] }
        ]);
      }
    }
  }

  async sendDealerRejectionNotification(user: User): Promise<void> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.dealer_rejected.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.dealer_rejected.lang') || 'en_US';

      if (templateName) {
        await this.sendViaCloudAPI_Template(user.phone, templateName, langCode, [
          { type: 'body', parameters: [{ type: 'text', text: user.name }] }
        ]);
      }
    }
  }

  async sendUserRegistrationNotification(user: User): Promise<void> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.user_reg.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.user_reg.lang') || 'en_US';

      if (templateName) {
        await this.sendViaCloudAPI_Template(user.phone, templateName, langCode, [
          { type: 'body', parameters: [{ type: 'text', text: user.name }] }
        ]);
      }
    }
  }

  async sendDealerRegistrationNotification(user: User): Promise<void> {
    console.log('[DEBUG] sendDealerRegistrationNotification called for user:', user.name, user.phone);

    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    console.log('[DEBUG] Integration mode:', integrationMode);

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.dealer_reg.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.dealer_reg.lang') || 'en_US';

      console.log('[DEBUG] Template name:', templateName, 'Lang:', langCode);

      if (templateName) {
        console.log('[DEBUG] Sending template to:', user.phone);
        await this.sendViaCloudAPI_Template(user.phone, templateName, langCode, [
          { type: 'body', parameters: [{ type: 'text', text: user.name }] }
        ]);
      } else {
        console.warn('[WARNING] Dealer registration template name not configured!');
      }
    }
  }

  async sendAbandonedCartNotification(order: Order, user: User): Promise<void> {
    const integrationMode =
      (await this.settingsService.getSetting('whatsapp.integration_mode')) ||
      'deep_link';

    if (integrationMode === 'cloud_api') {
      const templateName = await this.settingsService.getSetting('whatsapp.template.abandoned_cart.name');
      const langCode = await this.settingsService.getSetting('whatsapp.template.abandoned_cart.lang') || 'en_US';

      if (templateName) {
        // Construct deep link or cart summary
        // Usually abandoned cart templates have a dynamic button or link parameter.
        // Assuming template has 1 parameter: User Name or Link
        // For safely, let's assume Body 1 = Name.
        // Deep linking back to cart: avatar-app://cart (if configured)

        await this.sendViaCloudAPI_Template(user.phone, templateName, langCode, [
          { type: 'body', parameters: [{ type: 'text', text: user.name }] }
        ]);
      }
    }
  }

  private async sendViaCloudAPI_Template(to: string, templateName: string, langCode: string, components: any[] = []): Promise<string> {
    const phoneId = await this.settingsService.getSetting('whatsapp.phone_id');
    const token = await this.settingsService.getSetting('whatsapp.access_token');

    if (!phoneId || !token) {
      console.warn('WhatsApp Cloud API Credentials missing in Settings');
      return 'Creds Missing';
    }

    console.log(`[WhatsApp API] Sending Template: ${templateName} to ${to}`);

    try {
      const response = await fetch(`https://graph.facebook.com/v17.0/${phoneId}/messages`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: to,
          type: 'template',
          template: {
            name: templateName,
            language: { code: langCode },
            components: components
          }
        })
      });

      const data = await response.json();
      if (!response.ok) {
        console.error('WhatsApp API Error:', JSON.stringify(data));
        return 'Error';
      }

      console.log(`[WhatsApp API] Success:`, JSON.stringify(data));
      return 'Sent';
    } catch (e) {
      console.error('WhatsApp Send Error', e);
      return 'Error';
    }
  }

  async testConnection(): Promise<any> {
    const phoneId = await this.settingsService.getSetting('whatsapp.phone_id');
    const token = await this.settingsService.getSetting('whatsapp.access_token');

    if (!phoneId || !token) {
      throw new Error('Missing Phone ID or Access Token in Settings');
    }

    try {
      const response = await fetch(`https://graph.facebook.com/v17.0/${phoneId}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(`Meta API Error: ${data.error?.message || JSON.stringify(data)}`);
      }

      return { success: true, data };
    } catch (e) {
      throw new Error(e.message);
    }
  }

  async testTemplate(phone: string, templateName: string, languageCode: string = 'en_US', type?: string): Promise<any> {
    const phoneId = await this.settingsService.getSetting('whatsapp.phone_id');
    const token = await this.settingsService.getSetting('whatsapp.access_token');

    if (!phoneId || !token) {
      throw new Error('Missing Phone ID or Access Token');
    }

    // Determine components based on type
    let components = [];

    if (type === 'order_placed' || type === 'order_status') {
      components = [
        {
          type: 'body',
          parameters: [
            { type: 'text', text: 'Test User' },
            { type: 'text', text: 'ORD-TEST-123' },
            { type: 'text', text: 'Processed' }
          ]
        }
      ];
    } else {
      // Default for OTP, Registration, etc (1 variable)
      components = [
        { type: 'body', parameters: [{ type: 'text', text: 'Test User' }] }
      ];
    }

    try {
      const response = await fetch(`https://graph.facebook.com/v17.0/${phoneId}/messages`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: phone,
          type: 'template',
          template: {
            name: templateName,
            language: { code: languageCode || 'en_US' },
            components: components
          }
        })
      });

      const data = await response.json();

      if (!response.ok) {
        // Return error details
        return { success: false, error: data };
      }

      return { success: true, data };
    } catch (e) {
      return { success: false, error: e.message };
    }
  }

  // ... keep private helper methods (buildDeepLink, formatOrderSummary etc) ...
  private buildDeepLink(order: Order, businessNumber: string): string {
    const summaryText = this.formatOrderSummary(order);
    const encodedText = encodeURIComponent(summaryText);
    return `https://wa.me/${businessNumber}?text=${encodedText}`;
  }

  private buildQuotationDeepLink(
    quotation: Quotation,
    businessNumber: string,
  ): string {
    const summaryText = this.formatQuotationSummary(quotation);
    const encodedText = encodeURIComponent(summaryText);
    return `https://wa.me/${businessNumber}?text=${encodedText}`;
  }

  private formatOrderSummary(order: Order): string {
    // ... existing logic ...
    const items = order.items || [];
    let text = `Order ${order.orderNo}\n\n`;
    items.slice(0, 5).forEach((item, index) => {
      const price = (item.dpPricePaise / 100).toFixed(2);
      text += `${index + 1}. ${item.name} (${item.qty}x) - ₹${price}\n`;
    });
    if (items.length > 5) text += `+ ${items.length - 5} more items\n\n`;
    const total = (order.grandTotalPaise / 100).toFixed(2);
    text += `Approx Total: ₹${total}\n\nWe will confirm details.`;
    return text;
  }

  private formatQuotationSummary(quotation: Quotation): string {
    // ... existing logic ...
    return `Quotation ${quotation.quotationNo}`;
  }
}


