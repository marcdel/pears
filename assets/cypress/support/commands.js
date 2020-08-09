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

const findAvailablePear = pearName => cy.get(`[data-cy="available-pear ${pearName}"]`)
const findAssignedPear = pearName => cy.get(`[data-cy="assigned-pear ${pearName}"]`)
const findTrack = (trackName) => cy.get(`[data-cy="track ${trackName}"]`)
const findLockTrackLink = (trackName) => cy.get(`[data-cy="lock-track ${trackName}"]`)
const findUnlockTrackLink = (trackName) => cy.get(`[data-cy="unlock-track ${trackName}"]`)
const findRemoveTrackLink = (trackName) => cy.get(`[data-cy="remove-track ${trackName}"]`)
const findTrackNameHeader = (trackName) => cy.get(`[data-cy="edit-track-name ${trackName}"]`)
const findEditTrackInput = (trackName) => cy.get(`[data-cy="track-name-input ${trackName}"]`)
const findEditTrackForm = (trackName) => cy.get(`[data-cy="edit-track-name-form ${trackName}"]`)

Cypress.Commands.add('findAvailablePear', findAvailablePear)
Cypress.Commands.add('findAssignedPear', findAssignedPear)

Cypress.Commands.add('pearAvailable', (pearName) => {
  return findAvailablePear(pearName).should('visible')
})

Cypress.Commands.add('findTrack', findTrack)

Cypress.Commands.add('trackExists', (trackName) => {
  return findTrack(trackName).should('visible')
})

Cypress.Commands.add('changeTrackName', (trackName, newTrackName) => {
  findTrackNameHeader(trackName).click()

  findEditTrackInput(trackName)
    .clear()
    .type(newTrackName)
    .should('have.value', newTrackName)

  return findEditTrackForm(trackName).submit()
})

Cypress.Commands.add('removeTrack', (trackName) => {
  return findRemoveTrackLink(trackName).click()
})

Cypress.Commands.add('lockTrack', (trackName) => {
  return findLockTrackLink(trackName).click()
})

Cypress.Commands.add('unlockTrack', (trackName) => {
  return findUnlockTrackLink(trackName).click()
})

Cypress.Commands.add('trackIsLocked', (trackName) => {
  return findUnlockTrackLink(trackName).should('visible')
})

Cypress.Commands.add('trackIsUnlocked', (trackName) => {
  return findLockTrackLink(trackName).should('visible')
})

Cypress.Commands.add('trackDoesNotExist', (trackName) => {
  return cy.contains(trackName).should('not.visible')
})

Cypress.Commands.add('pearIsInTrack', (pearName, trackName) => {
  return cy.findTrack(trackName).should('contain', pearName)
})