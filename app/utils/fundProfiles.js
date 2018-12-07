import { evolve, map, when, propEq, set, lensProp } from 'ramda'

export const cancelProfile = (state, id) => {
  const updateMatch = when(
    propEq('idProfile', id),
    set(lensProp('canceled'), true)
  )
  const transformation = { fundProfiles: map(updateMatch) }
  return evolve(transformation, state)
}
