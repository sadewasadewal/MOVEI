import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

interface UserRecord {
  id: string;
  name: string;
  email: string;
  role: 'customer' | 'scanner' | 'admin';
  phone?: string;
  device?: string;
  registered_at: string;
  password?: string;
  created_by?: 'admin' | 'mobile_app';
  venue?: string;
}

const usersFilePath = path.join(process.cwd(), 'data', 'users.json');

function readUsers(): UserRecord[] {
  try {
    if (!fs.existsSync(usersFilePath)) return [];
    const data = fs.readFileSync(usersFilePath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error reading users.json:', error);
    return [];
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const email = (body.email || '').trim().toLowerCase();
    const password = (body.password || '').trim();

    if (!email) {
      return NextResponse.json({ success: false, error: 'Email is required' }, { status: 400 });
    }

    const users = readUsers();
    const user = users.find((u) => u.email.toLowerCase() === email);

    if (!user) {
      // Not registered in admin portal
      return NextResponse.json({
        success: false,
        isRegistered: false,
        error: 'No account found. Customer accounts can sign up directly in the app. Staff accounts must be provisioned by Cinema Admin.'
      }, { status: 404 });
    }

    // If account is staff or has a password set, verify it
    if (user.password && user.password !== password) {
      return NextResponse.json({
        success: false,
        isRegistered: true,
        error: 'Invalid password. Please check your credentials provided by Cinema Administration.'
      }, { status: 401 });
    }

    return NextResponse.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone || '',
        created_by: user.created_by || 'admin',
        venue: user.venue || ''
      }
    });
  } catch (error) {
    console.error('Auth verify error:', error);
    return NextResponse.json({ success: false, error: 'Authentication service error' }, { status: 500 });
  }
}
