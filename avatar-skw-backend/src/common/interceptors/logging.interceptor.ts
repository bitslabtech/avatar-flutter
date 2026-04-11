import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, user } = request;
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const responseTime = Date.now() - now;
          const userId = user?.id || 'anonymous';
          const userRole = user?.role || 'none';
          
          // Log critical actions
          if (this.isCriticalAction(method, url)) {
            this.logger.log(
              `[${method}] ${url} - User: ${userId} (${userRole}) - ${responseTime}ms`,
            );
          }
        },
        error: (error) => {
          const responseTime = Date.now() - now;
          this.logger.error(
            `[${method}] ${url} - Error after ${responseTime}ms: ${error.message}`,
          );
        },
      }),
    );
  }

  private isCriticalAction(method: string, url: string): boolean {
    const criticalPaths = [
      '/dealers',
      '/prices/import',
      '/orders',
      '/admin',
      '/auth/register',
    ];
    return (
      ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method) ||
      criticalPaths.some((path) => url.includes(path))
    );
  }
}


