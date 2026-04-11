import { MigrationInterface, QueryRunner } from "typeorm";

export class AddIsGstInclusiveToProduct1775912147006 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "products" ADD "is_gst_inclusive" boolean NOT NULL DEFAULT false`
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "products" DROP COLUMN "is_gst_inclusive"`
        );
    }

}
