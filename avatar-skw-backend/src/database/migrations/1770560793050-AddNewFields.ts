import { MigrationInterface, QueryRunner } from "typeorm";

export class AddNewFields1770560793050 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Add `badge` to `products`
        // Using raw SQL for simplicity and robustness since metadata loading failed
        await queryRunner.query(`ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "badge" character varying`);

        // Add `landmark` and `label` to `addresses`
        await queryRunner.query(`ALTER TABLE "addresses" ADD COLUMN IF NOT EXISTS "landmark" character varying`);
        await queryRunner.query(`ALTER TABLE "addresses" ADD COLUMN IF NOT EXISTS "label" character varying`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "addresses" DROP COLUMN "label"`);
        await queryRunner.query(`ALTER TABLE "addresses" DROP COLUMN "landmark"`);
        await queryRunner.query(`ALTER TABLE "products" DROP COLUMN "badge"`);
    }

}
