// Simple z-score based anomaly detection
export function zScore(series: number[]) {
  const mean = series.reduce((a, b) => a + b, 0) / series.length
  const variance = series.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / series.length
  const sd = Math.sqrt(variance)
  return series.map(v => ({ value: v, z: sd === 0 ? 0 : (v - mean) / sd }))
}

export function detectAnomalies(series: number[], threshold = 3) {
  return zScore(series).filter(x => Math.abs(x.z) >= threshold)
}

export default { zScore, detectAnomalies }
