import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddShippingOverride1770560793051 implements MigrationInterface {
  name = 'AddShippingOverride1770560793051';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "orders" ADD "shipping_override_paise" bigint NULL DEFAULT NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "orders" DROP COLUMN "shipping_override_paise"`,
    );
  }
}
