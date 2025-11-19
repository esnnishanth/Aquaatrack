import Fuse from 'fuse.js'

export function createFuzzy(items: any[], keys: string[] = ['name']) {
  const fuse = new Fuse(items, { keys, threshold: 0.4 })
  return {
    search: (term: string) => (term ? fuse.search(term).map(r => r.item) : items),
    update: (newItems: any[]) => {
      // recreate fuse for simplicity
      return createFuzzy(newItems, keys)
    },
  }
}

export default createFuzzy
