import { MigrationInterface, QueryRunner } from "typeorm";

export class AddAbandonedCartNotificationTracking1738950000000 implements MigrationInterface {
    name = 'AddAbandonedCartNotificationTracking1738950000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        const table = await queryRunner.getTable("orders");
        const column = table.findColumnByName("abandoned_cart_notification_sent");

        if (!column) {
            await queryRunner.query(`
                ALTER TABLE "orders" 
                ADD COLUMN "abandoned_cart_notification_sent" boolean NOT NULL DEFAULT false
            `);
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "orders" 
            DROP COLUMN "abandoned_cart_notification_sent"
        `);
    }
}
