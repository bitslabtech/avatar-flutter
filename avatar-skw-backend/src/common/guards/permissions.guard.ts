import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY, RequiredPermission } from '../decorators/permissions.decorator';
import { User, UserRole } from '../../modules/users/entities/user.entity';

@Injectable()
export class PermissionsGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        const requiredPermission = this.reflector.getAllAndOverride<RequiredPermission>(PERMISSIONS_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        if (!requiredPermission) {
            return true;
        }

        const { user } = context.switchToHttp().getRequest();
        const currentUser: User = user;

        if (!currentUser) {
            return false;
        }

        // Super Admin bypasses all checks
        if (currentUser.role === UserRole.SUPER_ADMIN) {
            return true;
        }

        // Role must be Admin to even have permissions
        if (currentUser.role !== UserRole.ADMIN) {
            // Technically roles guard should handle this, but double check
            return false;
        }

        const userPermissions = currentUser.permissions || {};
        const resourceActions = userPermissions[requiredPermission.resource] || [];

        if (resourceActions.includes(requiredPermission.action)) {
            return true;
        }

        throw new ForbiddenException(`You do not have permission to ${requiredPermission.action} ${requiredPermission.resource}`);
    }
}
