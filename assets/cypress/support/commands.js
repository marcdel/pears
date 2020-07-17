// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

Cypress.Commands.add('createTeam', (name) => cy.request('POST', `e2e/teams?name=${name}`))
Cypress.Commands.add('deleteTeam', (id) => cy.request('DELETE', `e2e/teams/${id}`))

Cypress.Commands.add('fillInput', (label, value) => {
  cy.contains('label', label)
    .find('input')
    .type(value)
    .should('have.value', value)
})

Cypress.Commands.add('clickButton', (text) => cy.contains('button', text).click())
Cypress.Commands.add('clickLink', (text) => cy.contains('a', text).click())

function findAvailablePear(pearName) {
  return cy.get('.available-pear')
    .contains(pearName)
}

Cypress.Commands.add('findAvailablePear', findAvailablePear)

Cypress.Commands.add('pearAvailable', (pearName) => {
  return findAvailablePear(pearName).should('visible')
})

const findTrack = (trackName) => {
  return cy.get('.track').contains(trackName)
}

Cypress.Commands.add('findTrack', findTrack)

Cypress.Commands.add('trackExists', (trackName) => {
  return findTrack(trackName).should('visible')
})

Cypress.Commands.add('trackDoesNotExist', (trackName) => {
  return cy.contains(trackName).should('not.visible')
})