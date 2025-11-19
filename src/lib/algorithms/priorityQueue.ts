// Min-heap priority queue (binary heap)
export class PriorityQueue<T> {
  private heap: { key: number; value: T }[] = []

  private swap(i: number, j: number) {
    const t = this.heap[i]
    this.heap[i] = this.heap[j]
    this.heap[j] = t
  }

  private parent(i: number) {
    return Math.floor((i - 1) / 2)
  }
  private left(i: number) {
    return i * 2 + 1
  }
  private right(i: number) {
    return i * 2 + 2
  }

  push(key: number, value: T) {
    this.heap.push({ key, value })
    let i = this.heap.length - 1
    while (i > 0 && this.heap[this.parent(i)].key > this.heap[i].key) {
      this.swap(this.parent(i), i)
      i = this.parent(i)
    }
  }

  pop(): T | undefined {
    if (!this.heap.length) return undefined
    const root = this.heap[0]
    const last = this.heap.pop()!
    if (this.heap.length) {
      this.heap[0] = last
      this.heapify(0)
    }
    return root.value
  }

  private heapify(i: number) {
    const l = this.left(i)
    const r = this.right(i)
    let smallest = i
    if (l < this.heap.length && this.heap[l].key < this.heap[smallest].key) smallest = l
    if (r < this.heap.length && this.heap[r].key < this.heap[smallest].key) smallest = r
    if (smallest !== i) {
      this.swap(i, smallest)
      this.heapify(smallest)
    }
  }

  peek(): T | undefined {
    return this.heap.length ? this.heap[0].value : undefined
  }

  size() {
    return this.heap.length
  }
}

export default PriorityQueue
