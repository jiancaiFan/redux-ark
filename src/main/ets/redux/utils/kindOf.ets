import { ReduxValue } from '../types/actions'

export type CheckValue = ReduxValue

function miniKindOf(value: CheckValue): string {
  if (value === undefined) {
    return 'undefined'
  }

  if (value === null) {
    return 'null'
  }

  const type = typeof value
  switch (type) {
    case 'boolean':
    case 'string':
    case 'number':
      return type
    default:
      break
  }

  if (Array.isArray(value)) {
    return 'array'
  }

  if (value instanceof Date) {
    return 'date'
  }

  if (value instanceof Error) {
    return 'error'
  }

  if (value instanceof RegExp) {
    return 'regexp'
  }

  if (value instanceof Map) {
    return 'Map'
  }

  if (value instanceof Set) {
    return 'Set'
  }

  if (value instanceof WeakMap) {
    return 'WeakMap'
  }

  if (value instanceof WeakSet) {
    return 'WeakSet'
  }

  if (value instanceof Promise) {
    return 'Promise'
  }

  return 'object'
}

export function kindOf(value: CheckValue): string {
  return miniKindOf(value)
}
