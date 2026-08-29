import { CheckValue } from './kindOf'

export function isPlainObject(obj: CheckValue): boolean {
  if (typeof obj !== 'object' || obj === null || Array.isArray(obj)) {
    return false
  }

  if (
    obj instanceof Date ||
    obj instanceof Error ||
    obj instanceof RegExp ||
    obj instanceof Map ||
    obj instanceof Set ||
    obj instanceof WeakMap ||
    obj instanceof WeakSet ||
    obj instanceof Promise
  ) {
    return false
  }

  return true
}
