import { Action, Dispatch, Middleware, MiddlewareAPI, Reducer, Store, applyMiddleware, createConcurrentStore } from '../index'

export class HomeState {
  loading: boolean
  title: string

  constructor(loading: boolean = false, title: string = '') {
    this.loading = loading
    this.title = title
  }
}

export class HomeLoadingAction implements Action {
  type: string = 'home/loading'
}

export class HomeLoadedAction implements Action {
  type: string = 'home/loaded'
  title: string

  constructor(title: string) {
    this.title = title
  }
}

export class HomeReducer implements Reducer<HomeState> {
  reduce(state: HomeState | undefined, action: Action): HomeState {
    const currentState = state === undefined ? new HomeState() : state

    switch (action.type) {
      case 'home/loading':
        return new HomeState(true, currentState.title)
      case 'home/loaded':
        const loaded = action as HomeLoadedAction
        return new HomeState(false, loaded.title)
      default:
        return currentState
    }
  }
}

export class HomeMiddleware implements Middleware<HomeState> {
  dispatch(store: MiddlewareAPI<HomeState>, next: Dispatch<Action>, action: Action): Action {
    return next.dispatch(action)
  }
}

export function createHomeStore(): Store<HomeState, Action> {
  return createConcurrentStore<HomeState, Action>(
    new HomeReducer(),
    new HomeState(),
    applyMiddleware<HomeState, Action>(new HomeMiddleware())
  )
}
