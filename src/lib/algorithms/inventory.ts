// EOQ and 0/1 knapsack prototype
export function eoq(demandPerPeriod: number, setupCost: number, holdingCostPerUnit: number) {
  // EOQ = sqrt( (2 * D * S) / H )
  if (holdingCostPerUnit <= 0) return null
  return Math.sqrt((2 * demandPerPeriod * setupCost) / holdingCostPerUnit)
}

export function knapsack(values: number[], weights: number[], capacity: number) {
  const n = values.length
  const dp: number[][] = Array.from({ length: n + 1 }, () => Array(capacity + 1).fill(0))
  for (let i = 1; i <= n; i++) {
    for (let w = 0; w <= capacity; w++) {
      if (weights[i - 1] <= w) {
        dp[i][w] = Math.max(dp[i - 1][w], dp[i - 1][w - weights[i - 1]] + values[i - 1])
      } else dp[i][w] = dp[i - 1][w]
    }
  }
  // reconstruct chosen items
  let w = capacity
  const chosen: number[] = []
  for (let i = n; i > 0; i--) {
    if (dp[i][w] !== dp[i - 1][w]) {
      chosen.push(i - 1)
      w -= weights[i - 1]
    }
  }
  return { value: dp[n][capacity], chosen: chosen.reverse() }
}

export default { eoq, knapsack }
