import { Action } from './actions'
import { Reducer } from './reducers'

export interface Dispatch<A extends Action = Action> {
  dispatch(action: A): A
}

export interface StoreSubscriber {
  onStateChanged(): void
}

export interface Observer<S> {
  next(value: S): void
}

export interface SubscriptionRemover {
  removeSubscription(id: number): void
}

export class StoreSubscription {
  private remover: SubscriptionRemover
  private id: number
  private active: boolean = true

  constructor(remover: SubscriptionRemover, id: number) {
    this.remover = remover
    this.id = id
  }

  unsubscribe(): void {
    if (!this.active) {
      return
    }
    this.active = false
    this.remover.removeSubscription(this.id)
  }
}

export type Unsubscribe = StoreSubscription

export type ListenerCallback = StoreSubscriber

export interface Observable<S> {
  subscribe(observer: Observer<S>): StoreSubscription
  observable(): Observable<S>
}

export interface Store<S = Object, A extends Action = Action> extends Dispatch<A> {
  getState(): S
  subscribe(listener: StoreSubscriber): StoreSubscription
  replaceReducer(nextReducer: Reducer<S, A>): void
  observable(): Observable<S>
}

export interface StoreCreator<S = Object, A extends Action = Action> {
  create(reducer: Reducer<S, A>, preloadedState?: S, enhancer?: StoreEnhancer<S, A>): Store<S, A>
}

export abstract class Operator<T> {
  abstract apply(value: T): T
}

export type StoreEnhancer<S = Object, A extends Action = Action> = Operator<StoreCreator<S, A>>

export type StoreEnhancerStoreCreator<S = Object, A extends Action = Action> = StoreCreator<S, A>
