import { NextRequest } from 'next/server'
import createFuzzy from '@/lib/algorithms/fuzzy'

export async function POST(req: NextRequest) {
  const body = await req.json()
  const { items = [], keys = ['name'], term = '' } = body
  const fuzzy = createFuzzy(items, keys)
  const results = fuzzy.search(term)
  return new Response(JSON.stringify({ results }), { status: 200 })
}
