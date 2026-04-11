import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { OrdersService } from '../orders/orders.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';

@Injectable()
export class SchedulerService {
    private readonly logger = new Logger(SchedulerService.name);

    constructor(
        private readonly ordersService: OrdersService,
        private readonly whatsappService: WhatsAppService,
        private readonly notificationsService: NotificationsService,
    ) { }

    // Run every 6 hours for more responsive notifications
    // Format: '0 */6 * * *' = at minute 0 of every 6th hour (0:00, 6:00, 12:00, 18:00)
    @Cron('0 */6 * * *')
    async handleAbandonedCarts() {
        this.logger.log('Running Abandoned Cart Cron Job...');

        try {
            // Find carts updated > 24 hours ago, but < 7 days ago (168 hours)
            // Only get carts that haven't been notified yet
            const abandonedCarts = await this.ordersService.getAbandonedCarts(24, 168);

            this.logger.log(`Found ${abandonedCarts.length} abandoned carts.`);

            for (const order of abandonedCarts) {
                if (order.user) {
                    // 1. In-App Notification
                    try {
                        await this.notificationsService.create(
                            order.user.id,
                            'Forgotten Items? 🛒',
                            'You have items left in your cart. Complete your purchase now!',
                            NotificationType.CART_REMINDER,
                            { orderId: order.id } // passing order ID if we want to navigate to cart
                        );
                    } catch (e) {
                        this.logger.error(`Failed to send In-App notification to ${order.user.id}`, e);
                    }

                    // 2. WhatsApp Notification
                    if (order.user.phone) {
                        try {
                            await this.whatsappService.sendAbandonedCartNotification(order, order.user);
                            this.logger.log(`Sent notification to ${order.user.phone} for Order draft ${order.id}`);
                        } catch (e) {
                            this.logger.error(`Failed to notify ${order.user.phone}`, e);
                        }
                    }

                    // 3. Mark cart as notified to prevent duplicate notifications
                    try {
                        await this.ordersService.markAbandonedCartNotified(order.id);
                        this.logger.log(`Marked cart ${order.id} as notified`);
                    } catch (e) {
                        this.logger.error(`Failed to mark cart ${order.id} as notified`, e);
                    }
                }
            }
        } catch (e) {
            this.logger.error('Error in Abandoned Cart Job', e);
        }
    }
}
