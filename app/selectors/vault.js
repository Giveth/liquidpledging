import { createSelector } from 'reselect'

export const getAuthorizations = createSelector(
  [vaultEvents => vaultEvents.filter(event => event.event === 'AuthorizePayment')],
  event => event
)
