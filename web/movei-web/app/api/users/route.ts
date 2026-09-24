import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export interface UserRecord {
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
    if (!fs.existsSync(usersFilePath)) {
      fs.mkdirSync(path.dirname(usersFilePath), { recursive: true });
      fs.writeFileSync(usersFilePath, '[]', 'utf8');
      return [];
    }
    const data = fs.readFileSync(usersFilePath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error reading users.json:', error);
    return [];
  }
}

function writeUsers(users: UserRecord[]): boolean {
  try {
    fs.mkdirSync(path.dirname(usersFilePath), { recursive: true });
    fs.writeFileSync(usersFilePath, JSON.stringify(users, null, 2), 'utf8');
    return true;
  } catch (error) {
    console.error('Error writing users.json:', error);
    return false;
  }
}

export async function GET() {
  const users = readUsers();
  return NextResponse.json(users);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const users = readUsers();

    const email = (body.email || '').trim().toLowerCase();
    const name = (body.name || body.fullName || '').trim() || 'Movie Fan';
    const role = (body.role || 'customer') as 'customer' | 'scanner' | 'admin';
    const id = body.id || `u-${Date.now()}`;
    const phone = body.phone || '';
    const device = body.device || (body.created_by === 'admin' ? 'Admin Portal' : 'iOS App (MOVEI)');
    const password = body.password ? String(body.password).trim() : undefined;
    const created_by = body.created_by || (role !== 'customer' ? 'admin' : 'mobile_app');
    const venue = body.venue || '';

    const existingIndex = users.findIndex(
      (u) => u.id === id || (email && u.email.toLowerCase() === email)
    );

    let updatedUser: UserRecord;
    if (existingIndex >= 0) {
      updatedUser = {
        ...users[existingIndex],
        name: name || users[existingIndex].name,
        role: role || users[existingIndex].role,
        phone: phone || users[existingIndex].phone,
        device: device || users[existingIndex].device,
        password: password !== undefined ? password : users[existingIndex].password,
        created_by: created_by || users[existingIndex].created_by,
        venue: venue || users[existingIndex].venue,
      };
      users[existingIndex] = updatedUser;
    } else {
      updatedUser = {
        id,
        name,
        email: email || `user_${Date.now()}@cinema.com`,
        role,
        phone,
        device,
        registered_at: new Date().toISOString(),
        password,
        created_by,
        venue,
      };
      users.unshift(updatedUser);
    }

    writeUsers(users);
    return NextResponse.json({ success: true, user: updatedUser });
  } catch (error) {
    console.error('Failed to create/update user:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const all = searchParams.get('all');

    if (all === 'true') {
      writeUsers([]);
      return NextResponse.json({ success: true, message: 'All users cleared.' });
    }

    if (!id) {
      return NextResponse.json({ error: 'User ID is required' }, { status: 400 });
    }

    const users = readUsers();
    const filtered = users.filter((u) => u.id !== id);
    writeUsers(filtered);

    return NextResponse.json({ success: true, message: 'User deleted.' });
  } catch (error) {
    console.error('Failed to delete user:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
