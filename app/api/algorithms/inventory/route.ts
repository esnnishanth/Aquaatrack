import { NextRequest } from 'next/server'
import { eoq, knapsack } from '@/lib/algorithms/inventory'

export async function POST(req: NextRequest) {
  const { demand = 0, setup = 0, holding = 0, items = [], capacity = 0 } = await req.json()
  const q = eoq(demand, setup, holding)
  let knap = null
  if (items.length && capacity > 0) {
    const values = items.map((i: any) => i.value)
    const weights = items.map((i: any) => i.weight)
    knap = knapsack(values, weights, capacity)
  }
  return new Response(JSON.stringify({ eoq: q, knapsack: knap }), { status: 200 })
}
