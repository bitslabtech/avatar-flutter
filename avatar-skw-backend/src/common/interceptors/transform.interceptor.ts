import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map((data) => {
        // Convert paise to ₹ and filter sensitive fields
        return this.transformData(data);
      }),
    );
  }

  private transformData(data: any): any {
    if (data === null || data === undefined) {
      return data;
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.transformData(item));
    }

    if (typeof data === 'object') {
      const transformed: any = {};
      
      for (const [key, value] of Object.entries(data)) {
        // Filter sensitive fields
        if (
          key === 'password_hash' ||
          key === 'password' ||
          key === 'dealer_discount_pct' ||
          key === 'discount_applied_paise' ||
          key === 'internal_total_paise' ||
          key === 'grand_total_payable_internal_paise' ||
          key.includes('_internal') ||
          key.includes('_secret')
        ) {
          continue;
        }

        // Convert paise fields to display format
        if (key.endsWith('_paise') && typeof value === 'number') {
          const displayKey = key.replace('_paise', '_display');
          transformed[displayKey] = this.formatCurrency(value / 100);
        } else if (key.endsWith('_paise')) {
          // Skip internal paise fields, only keep display versions
          continue;
        } else {
          transformed[key] = this.transformData(value);
        }
      }

      return transformed;
    }

    return data;
  }

  private formatCurrency(amount: number): string {
    return `₹${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
  }
}


