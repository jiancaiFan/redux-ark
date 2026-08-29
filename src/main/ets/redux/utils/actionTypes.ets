function randomString(): string {
  return Math.random().toString(36).substring(7).split('').join('.')
}

export default class ActionTypes {
  static INIT: string = '@@redux/INIT' + randomString()
  static REPLACE: string = '@@redux/REPLACE' + randomString()

  static PROBE_UNKNOWN_ACTION(): string {
    return '@@redux/PROBE_UNKNOWN_ACTION' + randomString()
  }
}
