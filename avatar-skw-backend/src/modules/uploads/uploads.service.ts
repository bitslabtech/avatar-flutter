import { Injectable } from '@nestjs/common';

@Injectable()
export class UploadsService {
  handleFileUpload(file: Express.Multer.File) {
    // In a real production app, you might upload to S3 here.
    // For local storage, we just return the path relative to the server URL.

    // Construct the URL. Assuming the server serves /uploads/filename
    // The client needs to prepend the base URL, or we can return a relative path.
    // Returning a relative path is safer for environment portability.

    return {
      originalname: file.originalname,
      filename: file.filename,
      path: `/uploads/${file.filename}`,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}
