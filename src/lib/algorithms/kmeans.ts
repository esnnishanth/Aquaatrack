// Simple k-means for numeric feature vectors
export function kmeans(data: number[][], k: number, iterations = 20) {
  if (!data.length || k <= 0) return { centroids: [], labels: [] }
  const dims = data[0].length
  // init centroids to first k points (simple)
  const centroids = data.slice(0, k).map(d => d.slice())
  const labels = new Array(data.length).fill(0)

  for (let it = 0; it < iterations; it++) {
    // assign
    for (let i = 0; i < data.length; i++) {
      let best = 0
      let bestDist = Infinity
      for (let c = 0; c < k; c++) {
        let dist = 0
        for (let d = 0; d < dims; d++) dist += Math.pow(data[i][d] - centroids[c][d], 2)
        if (dist < bestDist) {
          bestDist = dist
          best = c
        }
      }
      labels[i] = best
    }
    // update
    const sums = Array.from({ length: k }, () => Array(dims).fill(0))
    const counts = Array(k).fill(0)
    for (let i = 0; i < data.length; i++) {
      const c = labels[i]
      counts[c]++
      for (let d = 0; d < dims; d++) sums[c][d] += data[i][d]
    }
    for (let c = 0; c < k; c++) {
      if (counts[c] === 0) continue
      for (let d = 0; d < dims; d++) centroids[c][d] = sums[c][d] / counts[c]
    }
  }

  return { centroids, labels }
}

export default kmeans
