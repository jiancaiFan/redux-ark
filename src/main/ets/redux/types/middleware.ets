import { Action } from './actions'
import { Dispatch } from './store'

export interface MiddlewareAPI<S = Object> {
  dispatch(action: Action): Action
  getState(): S
}

export interface Middleware<S = Object> {
  dispatch(api: MiddlewareAPI<S>, next: Dispatch<Action>, action: Action): Action
}
