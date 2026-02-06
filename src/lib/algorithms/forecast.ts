// Simple exponential smoothing utilities
export function exponentialSmoothing(series: number[], alpha = 0.3) {
  if (!series.length) return []
  const result: number[] = [series[0]]
  for (let i = 1; i < series.length; i++) {
    result.push(alpha * series[i] + (1 - alpha) * result[i - 1])
  }
  return result
}

export function forecastNext(series: number[], alpha = 0.3) {
  const smoothed = exponentialSmoothing(series, alpha)
  if (!smoothed.length) return null
  // naive forecast: use last smoothed value
  return smoothed[smoothed.length - 1]
}

export default { exponentialSmoothing, forecastNext }
