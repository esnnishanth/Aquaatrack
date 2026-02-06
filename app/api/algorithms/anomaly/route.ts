import { NextRequest } from 'next/server'
import { detectAnomalies } from '@/lib/algorithms/anomaly'

export async function POST(req: NextRequest) {
  const { series = [], threshold = 3 } = await req.json()
  const anomalies = detectAnomalies(series, threshold)
  return new Response(JSON.stringify({ anomalies }), { status: 200 })
}
