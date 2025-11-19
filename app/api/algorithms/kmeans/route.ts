import { NextRequest } from 'next/server'
import kmeans from '@/lib/algorithms/kmeans'

export async function POST(req: NextRequest) {
  const { data = [], k = 2, iterations = 20 } = await req.json()
  const res = kmeans(data, k, iterations)
  return new Response(JSON.stringify(res), { status: 200 })
}
