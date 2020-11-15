export function addPear(pearName) {
  cy.clickButton('Pear')

  cy.contains('label', 'Pear')

  cy.get('[data-cy=add-pear-input]')
    .type(pearName)
    .should('have.value', pearName)

  cy.clickButton('Add')

  cy.pearIsAvailable(pearName)

  cy.get('.phx-modal')
    .should('not.be.visible')
}

export function addTrack(trackName) {
  cy.clickButton('Track')

  cy.contains('label', 'Track')

  cy.get('[data-cy=add-track-input]')
    .type(trackName)
    .should('have.value', trackName)

  cy.clickButton('Add')

  cy.trackExists(trackName)

  cy.get('.phx-modal')
    .should('not.be.visible')
}