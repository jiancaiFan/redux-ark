import { Operator } from './types/store'

class IdentityOperator<T> extends Operator<T> {
  apply(value: T): T {
    return value
  }
}

class ComposedOperator<T> extends Operator<T> {
  private operators: Operator<T>[]

  constructor(operators: Operator<T>[]) {
    super()
    this.operators = operators
  }

  apply(value: T): T {
    let result = value
    for (let i = this.operators.length - 1; i >= 0; i--) {
      result = this.operators[i].apply(result)
    }
    return result
  }
}

export function compose<T>(...operators: Operator<T>[]): Operator<T> {
  if (operators.length === 0) {
    return new IdentityOperator<T>()
  }

  if (operators.length === 1) {
    return operators[0]
  }

  return new ComposedOperator<T>(operators)
}
