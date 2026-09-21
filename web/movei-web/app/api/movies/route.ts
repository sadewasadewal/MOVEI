import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';
import { MOCK_MOVIES } from '@/lib/mock-data';
import { Movie } from '@/types';

const DATA_FILE = path.join(process.cwd(), 'data', 'movies.json');

async function getMovies(): Promise<Movie[]> {
  try {
    const data = await fs.readFile(DATA_FILE, 'utf-8');
    return JSON.parse(data);
  } catch {
    // Initialize with mock movies if file not yet created
    await saveMovies(MOCK_MOVIES);
    return MOCK_MOVIES;
  }
}

async function saveMovies(movies: Movie[]): Promise<void> {
  const dir = path.dirname(DATA_FILE);
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch {}
  await fs.writeFile(DATA_FILE, JSON.stringify(movies, null, 2), 'utf-8');
}

// GET /api/movies?published=true
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const onlyPublished = searchParams.get('published') === 'true';

  const host = request.headers.get('host') || 'Sandews-MacBook-Air.local:3000';
  const proto = request.headers.get('x-forwarded-proto') || 'http';
  const baseUrl = `${proto}://${host}`;

  const movies = await getMovies();
  const filtered = onlyPublished ? movies.filter(m => m.status === 'published') : movies;

  const normalizeUploadUrl = (rawUrl?: string) => {
    if (!rawUrl) return '';
    if (rawUrl.startsWith('/uploads/')) {
      return `${baseUrl}${rawUrl}`;
    }
    if (rawUrl.includes('/uploads/')) {
      const uploadPath = rawUrl.substring(rawUrl.indexOf('/uploads/'));
      return `${baseUrl}${uploadPath}`;
    }
    return rawUrl;
  };

  const results = filtered.map(m => {
    const pUrl = normalizeUploadUrl(m.poster_url);
    const bUrl = normalizeUploadUrl(m.backdrop_url) || pUrl;
    return {
      ...m,
      poster_url: pUrl,
      backdrop_url: bUrl
    };
  });

  return NextResponse.json(results, {
    headers: {
      'Cache-Control': 'no-store, max-age=0',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

// POST /api/movies (Create new movie)
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const movies = await getMovies();

    const poster = body.poster_url || body.posterURL || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600';
    const backdrop = body.backdrop_url || body.backdropURL || poster;

    const newMovie: Movie = {
      id: body.id || `m-${Date.now()}`,
      title: body.title || 'Untitled',
      slug: body.slug || (body.title || '').toLowerCase().replace(/[^a-z0-9]/g, '-'),
      tagline: body.tagline || '',
      description: body.description || '',
      poster_url: poster,
      backdrop_url: backdrop,
      trailer_url: body.trailer_url || body.trailerURL || '',
      runtime_minutes: Number(body.runtime_minutes || body.runtimeMinutes) || 120,
      rating: Number(body.rating) || 8.0,
      release_date: body.release_date || body.releaseDate || new Date().toISOString().split('T')[0],
      genres: Array.isArray(body.genres) && body.genres.length > 0 ? body.genres : ['Action'],
      language: body.language || 'English',
      age_rating: body.age_rating || body.ageRating || 'PG-13',
      status: body.status || 'published',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const updated = [newMovie, ...movies.filter(m => m.id !== newMovie.id)];
    await saveMovies(updated);

    return NextResponse.json(newMovie, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to create movie' }, { status: 500 });
  }
}

// PUT /api/movies (Update movie status or details)
export async function PUT(request: Request) {
  try {
    const body = await request.json();
    if (!body.id) {
      return NextResponse.json({ error: 'Movie ID required' }, { status: 400 });
    }

    const movies = await getMovies();
    let updatedMovie: Movie | null = null;

    const nextMovies: Movie[] = movies.map(m => {
      if (m.id === body.id) {
        const item: Movie = {
          ...m,
          ...body,
          updated_at: new Date().toISOString()
        };
        updatedMovie = item;
        return item;
      }
      return m;
    });

    if (!updatedMovie) {
      return NextResponse.json({ error: 'Movie not found' }, { status: 404 });
    }

    await saveMovies(nextMovies);
    return NextResponse.json(updatedMovie);
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to update movie' }, { status: 500 });
  }
}

// DELETE /api/movies?id=...
export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) {
      return NextResponse.json({ error: 'Movie ID is required' }, { status: 400 });
    }

    const movies = await getMovies();
    const filtered = movies.filter(m => m.id !== id);
    await saveMovies(filtered);

    return NextResponse.json({ success: true, removedId: id });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to delete movie' }, { status: 500 });
  }
}
