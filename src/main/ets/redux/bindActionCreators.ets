import { Action, ActionCreator, ActionCreatorArgs, ActionCreatorsMapObject } from './types/actions'
import { Dispatch } from './types/store'

class BoundActionCreator<A extends Action> implements ActionCreator<A> {
  private actionCreator: ActionCreator<A>
  private dispatchRef: Dispatch<Action>

  constructor(actionCreator: ActionCreator<A>, dispatchRef: Dispatch<Action>) {
    this.actionCreator = actionCreator
    this.dispatchRef = dispatchRef
  }

  create(args: ActionCreatorArgs): A {
    return this.dispatchRef.dispatch(this.actionCreator.create(args)) as A
  }
}

function bindActionCreator<A extends Action>(
  actionCreator: ActionCreator<A>,
  dispatchRef: Dispatch<Action>
): ActionCreator<A> {
  return new BoundActionCreator<A>(actionCreator, dispatchRef)
}

export function bindActionCreators<A extends Action>(
  actionCreators: ActionCreator<A>,
  dispatchRef: Dispatch<Action>
): ActionCreator<A>
export function bindActionCreators<A extends Action>(
  actionCreators: ActionCreatorsMapObject<A>,
  dispatchRef: Dispatch<Action>
): ActionCreatorsMapObject<A>
export function bindActionCreators<A extends Action>(
  actionCreators: ActionCreator<A> | ActionCreatorsMapObject<A>,
  dispatchRef: Dispatch<Action>
): ActionCreator<A> | ActionCreatorsMapObject<A> {
  if (actionCreators instanceof ActionCreatorsMapObject) {
    const boundActionCreators = new ActionCreatorsMapObject<A>()
    for (let i = 0; i < actionCreators.entries.length; i++) {
      const entry = actionCreators.entries[i]
      boundActionCreators.add(entry.key, bindActionCreator(entry.creator, dispatchRef))
    }
    return boundActionCreators
  }

  return bindActionCreator(actionCreators, dispatchRef)
}
