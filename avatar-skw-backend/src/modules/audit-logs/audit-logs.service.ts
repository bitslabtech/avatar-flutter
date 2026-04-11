import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog, AuditLogActionType, AuditLogStatus } from './entities/audit-log.entity';

@Injectable()
export class AuditLogsService {
    constructor(
        @InjectRepository(AuditLog)
        private auditLogRepository: Repository<AuditLog>,
    ) { }

    async logAction(
        userId: string,
        actionType: AuditLogActionType,
        title: string,
        details: string,
        ipAddress?: string,
        status: AuditLogStatus = AuditLogStatus.SUCCESS,
        entityId?: string,
        entityType?: string,
        deviceInfo?: string,
    ): Promise<AuditLog> {
        const log = this.auditLogRepository.create({
            userId,
            actionType,
            title,
            details,
            ipAddress,
            status,
            entityId,
            entityType,
            deviceInfo,
        });
        return this.auditLogRepository.save(log);
    }

    async findAll(userId?: string): Promise<AuditLog[]> {
        console.log(`[AuditLogs] Fetching logs for userId: ${userId}`);
        const query = this.auditLogRepository.createQueryBuilder('log')
            .leftJoinAndSelect('log.user', 'user')
            .orderBy('log.createdAt', 'DESC');

        if (userId) {
            query.where('log.userId = :userId', { userId });
        }

        try {
            const logs = await query.getMany();
            console.log(`[AuditLogs] Found ${logs.length} logs`);

            // Map to snake_case for frontend compatibility
            return logs.map(log => ({
                id: log.id,
                user_id: log.userId,
                action_type: log.actionType,
                title: log.title,
                details: log.details,
                status: log.status,
                entity_id: log.entityId,
                entity_type: log.entityType,
                ip_address: log.ipAddress,
                device_info: log.deviceInfo,
                created_at: log.createdAt,
                user: log.user
            })) as any;
        } catch (error) {
            console.error('[AuditLogs] Error fetching logs:', error);
            throw error;
        }
    }
}
