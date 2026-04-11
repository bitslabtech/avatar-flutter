import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateContentTable1739373600000 implements MigrationInterface {
    name = 'CreateContentTable1739373600000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            CREATE TABLE "contents" (
                "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "key" character varying NOT NULL,
                "title" character varying NOT NULL,
                "body" text NOT NULL,
                "isActive" boolean NOT NULL DEFAULT true,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "UQ_content_key" UNIQUE ("key"),
                CONSTRAINT "PK_content_id" PRIMARY KEY ("id")
            )
        `);

        // Seed default content
        await queryRunner.query(`
            INSERT INTO "contents" ("key", "title", "body") VALUES
            ('privacy_policy', 'Privacy Policy', '<h1>Privacy Policy</h1><p>Welcome to our Privacy Policy page. Here we describe how we handle your data.</p>'),
            ('terms_of_service', 'Terms of Service', '<h1>Terms of Service</h1><p>These are the terms of service for using our application.</p>'),
            ('return_policy', 'Return Policy', '<h1>Return Policy</h1><p>Details about our return and refund policy.</p>'),
            ('shipping_policy', 'Shipping Policy', '<h1>Shipping Policy</h1><p>Information regarding shipping and delivery.</p>')
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "contents"`);
    }

}
