import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const UPLOADS_DIR = path.join(process.cwd(), 'public', 'uploads', 'posters');

export async function POST(request: Request) {
  try {
    const contentType = request.headers.get('content-type') || '';
    const host = request.headers.get('host') || 'Sandews-MacBook-Air.local:3000';
    const proto = request.headers.get('x-forwarded-proto') || 'http';
    const baseUrl = `${proto}://${host}`;

    // Ensure uploads directory exists
    await fs.mkdir(UPLOADS_DIR, { recursive: true });

    if (contentType.includes('multipart/form-data')) {
      const formData = await request.formData();
      const file = formData.get('file') as File | null;

      if (!file) {
        return NextResponse.json({ error: 'No file provided in form data' }, { status: 400 });
      }

      // Check mime type
      const mime = file.type || '';
      if (!mime.startsWith('image/') && !file.name.match(/\.(png|jpg|jpeg|webp|gif)$/i)) {
        return NextResponse.json({ error: 'Only image files (PNG, JPG, WEBP) are allowed' }, { status: 400 });
      }

      const bytes = await file.arrayBuffer();
      const buffer = Buffer.from(bytes);

      // Clean file extension & safe filename
      const ext = path.extname(file.name) || '.png';
      const cleanBase = path.basename(file.name, ext).replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 30);
      const filename = `poster-${Date.now()}-${cleanBase}${ext.toLowerCase()}`;
      const filePath = path.join(UPLOADS_DIR, filename);

      await fs.writeFile(filePath, buffer);

      const relativeUrl = `/uploads/posters/${filename}`;
      const fullUrl = `${baseUrl}${relativeUrl}`;

      return NextResponse.json({
        success: true,
        filename,
        relativeUrl,
        url: fullUrl,
        size: buffer.length,
        mime: mime || 'image/png'
      }, {
        headers: {
          'Access-Control-Allow-Origin': '*'
        }
      });
    } else if (contentType.includes('application/json')) {
      // Base64 upload fallback
      const body = await request.json();
      const { data, filename: origName } = body;

      if (!data || typeof data !== 'string') {
        return NextResponse.json({ error: 'Invalid data URI payload' }, { status: 400 });
      }

      const matches = data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) {
        return NextResponse.json({ error: 'Invalid base64 image format' }, { status: 400 });
      }

      const mime = matches[1];
      const ext = mime.split('/')[1] || 'png';
      const buffer = Buffer.from(matches[2], 'base64');

      const cleanName = (origName || 'custom').replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 30);
      const filename = `poster-${Date.now()}-${cleanName}.${ext}`;
      const filePath = path.join(UPLOADS_DIR, filename);

      await fs.writeFile(filePath, buffer);

      const relativeUrl = `/uploads/posters/${filename}`;
      const fullUrl = `${baseUrl}${relativeUrl}`;

      return NextResponse.json({
        success: true,
        filename,
        relativeUrl,
        url: fullUrl,
        size: buffer.length,
        mime
      }, {
        headers: {
          'Access-Control-Allow-Origin': '*'
        }
      });
    } else {
      return NextResponse.json({ error: 'Unsupported Content-Type. Use multipart/form-data or application/json' }, { status: 400 });
    }
  } catch (error: any) {
    console.error('Upload error:', error);
    return NextResponse.json({ error: error.message || 'Upload processing failed' }, { status: 500 });
  }
}
