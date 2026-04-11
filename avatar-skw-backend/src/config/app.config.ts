import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  frontendUrl: process.env.FRONTEND_MOBILE_APP_URL,
  whatsappToken: process.env.WHATSAPP_CLOUD_API_TOKEN,
  whatsappPhoneId: process.env.WHATSAPP_PHONE_NUMBER_ID,
}));


