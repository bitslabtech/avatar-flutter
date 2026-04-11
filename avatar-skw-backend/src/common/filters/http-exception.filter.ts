import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { AppException } from '../exceptions/app.exception';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let errorCode = 'INTERNAL_SERVER_ERROR';
    let message = 'An unexpected error occurred';
    let details: any = {};

    if (exception instanceof AppException) {
      status = exception.getStatus();
      errorCode = exception.errorCode;
      message = exception.message;
      details = exception.details || {};
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      
      if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
      } else if (typeof exceptionResponse === 'object') {
        const responseObj = exceptionResponse as any;
        errorCode = responseObj.error || 'HTTP_EXCEPTION';
        message = responseObj.message || exception.message;
        
        // Handle validation errors
        if (Array.isArray(responseObj.message)) {
          errorCode = 'VALIDATION_ERROR';
          message = 'Validation failed';
          details = {
            fields: responseObj.message.map((msg: string) => {
              const match = msg.match(/^(\w+):/);
              return {
                field: match ? match[1] : 'unknown',
                message: msg,
              };
            }),
          };
        } else {
          details = responseObj.details || {};
        }
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      // Don't expose stack traces in production
      if (process.env.NODE_ENV === 'development') {
        details = { stack: exception.stack };
      }
    }

    // Never expose raw SQL/ORM errors
    if (message.includes('SQL') || message.includes('ORM') || message.includes('database')) {
      message = 'A database error occurred';
      errorCode = 'DATABASE_ERROR';
      details = {};
    }

    response.status(status).json({
      error: errorCode,
      message,
      details,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}


