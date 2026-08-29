import { Action } from '../types/actions'
import { isPlainObject } from './isPlainObject'

export function isAction(action: Action | null | undefined): boolean {
  if (action === null || action === undefined) {
    return false
  }

  return isPlainObject(action) && typeof action.type === 'string'
}
