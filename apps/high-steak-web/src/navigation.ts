export type BackNavigationState = {
  backTo: string
  backLabel: string
}

export function listItemBackState(backTo: string, backLabel: string): BackNavigationState {
  return { backTo, backLabel }
}
