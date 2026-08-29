import { Action, ReduxValue } from './types/actions'
import { Reducer, ReducersMapObject, StateObject } from './types/reducers'
import ActionTypes from './utils/actionTypes'
import warning from './utils/warning'

class CombinedInternalAction implements Action {
  type: string

  constructor(type: string) {
    this.type = type
  }
}

class CombinedReducer implements Reducer<StateObject, Action, StateObject> {
  private reducers: ReducersMapObject<ReduxValue, Action>
  private checked: boolean = false
  private unexpectedKeyCache: string[] = []

  constructor(reducers: ReducersMapObject<ReduxValue, Action>) {
    this.reducers = reducers
  }

  private assertReducerShape(): void {
    if (this.checked) {
      return
    }

    for (let i = 0; i < this.reducers.entries.length; i++) {
      const entry = this.reducers.entries[i]
      const initialState = entry.reducer.reduce(undefined, new CombinedInternalAction(ActionTypes.INIT))

      if (initialState === undefined) {
        throw new Error(
          'The slice reducer for key "' + entry.key + '" returned undefined during initialization.'
        )
      }

      const probeState = entry.reducer.reduce(undefined, new CombinedInternalAction(ActionTypes.PROBE_UNKNOWN_ACTION()))
      if (probeState === undefined) {
        throw new Error(
          'The slice reducer for key "' + entry.key + '" returned undefined when probed with a random type.'
        )
      }
    }

    this.checked = true
  }

  private hasReducerKey(key: string): boolean {
    for (let i = 0; i < this.reducers.entries.length; i++) {
      if (this.reducers.entries[i].key === key) {
        return true
      }
    }
    return false
  }

  private hasWarnedForKey(key: string): boolean {
    for (let i = 0; i < this.unexpectedKeyCache.length; i++) {
      if (this.unexpectedKeyCache[i] === key) {
        return true
      }
    }
    return false
  }

  private warnForUnexpectedKeys(state: StateObject, action: Action): void {
    if (action.type === ActionTypes.REPLACE) {
      return
    }

    const stateKeys = state.keys()
    const unexpectedKeys: string[] = []
    for (let i = 0; i < stateKeys.length; i++) {
      const key = stateKeys[i]
      if (!this.hasReducerKey(key) && !this.hasWarnedForKey(key)) {
        unexpectedKeys.push(key)
        this.unexpectedKeyCache.push(key)
      }
    }

    if (unexpectedKeys.length > 0) {
      warning(
        'Unexpected state keys "' + unexpectedKeys.join('\", \"') +
          '" were found. Unexpected keys will be ignored.'
      )
    }
  }

  reduce(state: StateObject | undefined, action: Action): StateObject {
    this.assertReducerShape()
    const actualState = state === undefined ? new StateObject() : state
    this.warnForUnexpectedKeys(actualState, action)
    let hasChanged = false
    const nextState = new StateObject()

    if (this.reducers.entries.length === 0) {
      warning('Store does not have a valid reducer.')
    }

    for (let i = 0; i < this.reducers.entries.length; i++) {
      const entry = this.reducers.entries[i]
      const previousStateForKey = actualState.get(entry.key)
      const nextStateForKey = entry.reducer.reduce(previousStateForKey, action)

      if (nextStateForKey === undefined) {
        throw new Error(
          'When called with action "' + action.type + '", the slice reducer for key "' +
            entry.key + '" returned undefined.'
        )
      }

      nextState.set(entry.key, nextStateForKey)
      hasChanged = hasChanged || nextStateForKey !== previousStateForKey
    }

    hasChanged = hasChanged || this.reducers.entries.length !== actualState.size()
    return hasChanged ? nextState : actualState
  }
}

export function combineReducers(reducers: ReducersMapObject<ReduxValue, Action>): Reducer<StateObject, Action> {
  return new CombinedReducer(reducers)
}
