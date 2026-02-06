import { NextRequest } from 'next/server'
import { forecastNext, exponentialSmoothing } from '@/lib/algorithms/forecast'

export async function POST(req: NextRequest) {
  const { series = [], alpha = 0.3 } = await req.json()
  const smoothed = exponentialSmoothing(series, alpha)
  const next = forecastNext(series, alpha)
  return new Response(JSON.stringify({ smoothed, next }), { status: 200 })
}
