import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GstController } from './gst.controller';
import { GstService } from './gst.service';
import { GstRate } from './entities/gst.entity';

@Module({
    imports: [TypeOrmModule.forFeature([GstRate])],
    controllers: [GstController],
    providers: [GstService],
    exports: [GstService],
})
export class GstModule { }
