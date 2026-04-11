import {
    Controller,
    Get,
    Patch,
    Param,
    Query,
    UseGuards,
    Request,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
    ApiTags, ApiOperation, ApiBearerAuth, ApiBody,
} from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
    constructor(private readonly notificationsService: NotificationsService) { }

    @Get()
    @ApiOperation({ summary: 'Get current user notifications' })
    async findAll(@Request() req, @Query('limit') limit = 20, @Query('offset') offset = 0) {
        return this.notificationsService.findAll(req.user.id, Number(limit), Number(offset));
    }

    @Get('unread-count')
    @ApiOperation({ summary: 'Get unread notification count' })
    async getUnreadCount(@Request() req) {
        return this.notificationsService.getUnreadCount(req.user.id);
    }

    @Patch('read-all')
    @ApiOperation({ summary: 'Mark all notifications as read' })
    async markAllAsRead(@Request() req) {
        return this.notificationsService.markAllAsRead(req.user.id);
    }

    @Get('debug-admins')
    @Public()
    @ApiOperation({ summary: 'Debug: List all admins' })
    async debugAdmins() {
        return this.notificationsService.checkAdmins();
    }

    @Patch(':id/read')
    @ApiOperation({ summary: 'Mark specific notification as read' })
    async markAsRead(@Request() req, @Param('id') id: string) {
        return this.notificationsService.markAsRead(req.user.id, id);
    }
}
