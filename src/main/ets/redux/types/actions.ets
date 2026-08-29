export type ReduxValue = string | number | boolean | Object | null | undefined

export class ActionCreatorArgs {
  values: ReduxValue[] = []

  constructor(values?: ReduxValue[]) {
    if (values !== undefined) {
      this.values = values
    }
  }
}

export interface Action<T extends string = string> {
  type: T
}

export interface ActionCreator<A extends Action = Action> {
  create(args: ActionCreatorArgs): A
}

export class ActionCreatorEntry<A extends Action = Action> {
  key: string
  creator: ActionCreator<A>

  constructor(key: string, creator: ActionCreator<A>) {
    this.key = key
    this.creator = creator
  }
}

export class ActionCreatorsMapObject<A extends Action = Action> {
  entries: ActionCreatorEntry<A>[] = []

  add(key: string, creator: ActionCreator<A>): ActionCreatorsMapObject<A> {
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].key === key) {
        this.entries[i] = new ActionCreatorEntry<A>(key, creator)
        return this
      }
    }
    this.entries.push(new ActionCreatorEntry<A>(key, creator))
    return this
  }
}
