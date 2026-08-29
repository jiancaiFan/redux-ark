import { Action, ReduxValue } from './actions'

export class StateEntry {
  key: string
  value: ReduxValue

  constructor(key: string, value: ReduxValue) {
    this.key = key
    this.value = value
  }
}

export class StateObject {
  entries: StateEntry[] = []

  get(key: string): ReduxValue {
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].key === key) {
        return this.entries[i].value
      }
    }
    return undefined
  }

  set(key: string, value: ReduxValue): void {
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].key === key) {
        this.entries[i].value = value
        return
      }
    }
    this.entries.push(new StateEntry(key, value))
  }

  has(key: string): boolean {
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].key === key) {
        return true
      }
    }
    return false
  }

  keys(): string[] {
    const result: string[] = []
    for (let i = 0; i < this.entries.length; i++) {
      result.push(this.entries[i].key)
    }
    return result
  }

  size(): number {
    return this.entries.length
  }
}

export interface Reducer<S = Object, A extends Action = Action, PreloadedState = S> {
  reduce(state: S | PreloadedState | undefined, action: A): S
}

export class ReducerEntry<S = ReduxValue, A extends Action = Action> {
  key: string
  reducer: Reducer<S, A, S>

  constructor(key: string, reducer: Reducer<S, A, S>) {
    this.key = key
    this.reducer = reducer
  }
}

export class ReducersMapObject<S = ReduxValue, A extends Action = Action> {
  entries: ReducerEntry<S, A>[] = []

  add(key: string, reducer: Reducer<S, A, S>): ReducersMapObject<S, A> {
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].key === key) {
        this.entries[i] = new ReducerEntry<S, A>(key, reducer)
        return this
      }
    }
    this.entries.push(new ReducerEntry<S, A>(key, reducer))
    return this
  }

  keys(): string[] {
    const result: string[] = []
    for (let i = 0; i < this.entries.length; i++) {
      result.push(this.entries[i].key)
    }
    return result
  }
}

export class StateFromReducersMapObject<M> extends StateObject {}

export class PreloadedStateShapeFromReducersMapObject<M> extends StateObject {}

export type ActionFromReducer<R> = Action

export type ActionFromReducersMapObject<M> = Action

export type ReducerFromReducersMapObject<M> = Reducer<StateFromReducersMapObject<M>, Action>
