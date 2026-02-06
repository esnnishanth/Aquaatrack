import 'dart:math' as math;

class KMeansResult {
  final List<List<double>> centroids;
  final List<int> labels;
  KMeansResult(this.centroids, this.labels);
}

KMeansResult kmeans(List<List<double>> points, int k, {int maxIter = 50}) {
  if (points.isEmpty || k <= 0) return KMeansResult([], []);
  final dim = points.first.length;
  final rand = math.Random(1234);

  // init centroids randomly
  final centroids = List.generate(k, (_) => List<double>.filled(dim, 0.0));
  for (var i = 0; i < k; i++) {
    centroids[i] = List.from(points[rand.nextInt(points.length)]);
  }

  final labels = List<int>.filled(points.length, 0);

  for (var iter = 0; iter < maxIter; iter++) {
    var changed = false;
    // assign
    for (var i = 0; i < points.length; i++) {
      var best = 0;
      var bestDist = double.infinity;
      for (var c = 0; c < k; c++) {
        var d = 0.0;
        for (var j = 0; j < dim; j++) {
          final diff = points[i][j] - centroids[c][j];
          d += diff * diff;
        }
        if (d < bestDist) {
          bestDist = d;
          best = c;
        }
      }
      if (labels[i] != best) {
        labels[i] = best;
        changed = true;
      }
    }

    // update
    final sums = List.generate(k, (_) => List<double>.filled(dim, 0.0));
    final counts = List<int>.filled(k, 0);
    for (var i = 0; i < points.length; i++) {
      final lbl = labels[i];
      counts[lbl]++;
      for (var j = 0; j < dim; j++) sums[lbl][j] += points[i][j];
    }
    for (var c = 0; c < k; c++) {
      if (counts[c] == 0) continue;
      for (var j = 0; j < dim; j++) centroids[c][j] = sums[c][j] / counts[c];
    }

    if (!changed) break;
  }

  return KMeansResult(centroids, labels);
}
