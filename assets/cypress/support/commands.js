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

import '@testing-library/cypress/add-commands'
require('@4tw/cypress-drag-drop')

Cypress.Commands.add('createTeam', (name) => cy.request('POST', `e2e/teams?name=${name}`))
Cypress.Commands.add('deleteTeam', (id) => cy.request('DELETE', `e2e/teams/${id}`))

Cypress.Commands.add('fillInput', (label, value) => {
  cy.contains('label', label)
    .find('input')
    .type(value)
    .should('have.value', value)
})

Cypress.Commands.add('clickButton', (text) => cy.findByRole('button', { name: text }).click())
Cypress.Commands.add('clickLink', (text) => cy.findByRole('a', { name: text }).click())

const findAvailablePearsList = pearName => cy.get('[data-cy="available-pears-list"]')
const findAvailablePear = pearName => cy.get(`[data-cy="available-pear ${pearName}"]`)
const findAssignedPear = pearName => cy.get(`[data-cy="assigned-pear ${pearName}"]`)
const trackSelector = trackName => `[data-cy="track ${trackName}"]`
const findTrack = (trackName) => cy.get(trackSelector(trackName))
const findTrash = () => cy.get('[data-cy="trash"]')
const findLockTrackLink = (trackName) => cy.get(`[data-cy="lock-track ${trackName}"]`)
const findUnlockTrackLink = (trackName) => cy.get(`[data-cy="unlock-track ${trackName}"]`)
const findRemoveTrackLink = (trackName) => cy.get(`[data-cy="remove-track ${trackName}"]`)
const findTrackNameHeader = (trackName) => cy.get(`[data-cy="edit-track-name ${trackName}"]`)
const findEditTrackInput = (trackName) => cy.get(`[data-cy="track-name-input ${trackName}"]`)
const findEditTrackForm = (trackName) => cy.get(`[data-cy="edit-track-name-form ${trackName}"]`)
const pearIsInTrack = (pearName, trackName) => findTrack(trackName).should('contain', pearName)

Cypress.Commands.add('findAvailablePearsList', findAvailablePearsList)
Cypress.Commands.add('findAvailablePear', findAvailablePear)
Cypress.Commands.add('findAssignedPear', findAssignedPear)
Cypress.Commands.add('findTrack', findTrack)
Cypress.Commands.add('findTrash', findTrash)

Cypress.Commands.add('pearIsAvailable', (pearName) => {
  return findAvailablePear(pearName).should('be.visible')
})

Cypress.Commands.add('trackExists', (trackName) => {
  return findTrack(trackName).should('be.visible')
})

Cypress.Commands.add('dragPearToUnassigned', (pearName) => {
  findAssignedPear(pearName)
    .drag('#unassigned')
})

Cypress.Commands.add('dragPearToTrash', (pearName) => {
  findAssignedPear(pearName).drag('#trash')
  findAvailablePear(pearName).drag('#trash')
})

Cypress.Commands.add('dragPearToTrack', (pearName, trackName) => {
  findAvailablePear(pearName)
    .drag(trackSelector(trackName))
})

Cypress.Commands.add('dragPearFromTrackToTrack', (pearName, fromTrack, toTrack) => {
  pearIsInTrack(pearName, fromTrack)

  findAssignedPear(pearName)
    .drag(trackSelector(toTrack))
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
  return findUnlockTrackLink(trackName).should('be.visible')
})

Cypress.Commands.add('trackIsUnlocked', (trackName) => {
  return findLockTrackLink(trackName).should('be.visible')
})

Cypress.Commands.add('trackDoesNotExist', (trackName) => {
  return cy.contains(trackName).should('not.be.visible')
})

Cypress.Commands.add('pearDoesNotExist', (pearName) => {
  return cy.contains(pearName).should('not.be.visible')
})

Cypress.Commands.add('pearIsInTrack', (pearName, trackName) => {
  return pearIsInTrack(pearName, trackName)
})