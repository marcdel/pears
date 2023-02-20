/// <reference types="cypress" />

import {addPear, addTrack} from "../support/helpers"

context('Full Journey', () => {
  const teamName = 'Team Cypress'
  const teamPassword = 'Cypress Password'

  beforeEach(() => {
    cy.deleteTeam(teamName)
    cy.toggleFlag('random_facilitator', false)

    cy.visit('/teams/register')
  })

  it('create team, add pears, add tracks, and recommend pears', () => {
    cy.fillInput('Name', teamName)
    cy.fillInput('Password', teamPassword)

    cy.clickButton('Register')

    cy.contains('Team created successfully.').should('be.visible')
    cy.location('pathname').should('include', '/teams/')
    cy.contains('h1', teamName)

    addPear('First Pear')
    addPear('Second Pear')

    addTrack('Feature Track')

    cy.clickButton('Suggest')

    cy.pearIsInTrack('First Pear', 'Feature Track')
    cy.pearIsInTrack('Second Pear', 'Feature Track')

    cy.clickButton('Save')
    cy.contains('Today\'s assigned pears have been recorded!').should('be.visible')

    cy.removeTrack('Feature Track')
    cy.trackDoesNotExist('Feature Track')

    cy.pearIsAvailable('First Pear')
    cy.pearIsAvailable('Second Pear')

    addTrack('Refactor Track')

    cy.findAvailablePear('First Pear').click()
    cy.findTrack('Refactor Track').click()
    cy.pearIsInTrack('First Pear', 'Refactor Track')

    cy.changeTrackName('Refactor Track', 'Super Important Track')
    cy.pearIsInTrack('First Pear', 'Super Important Track')
    cy.changeTrackName('Super Important Track', 'Refactor Track')

    cy.findAvailablePear('Second Pear').click()
    cy.findTrack('Refactor Track').click()
    cy.pearIsInTrack('Second Pear', 'Refactor Track')

    cy.findAssignedPear('Second Pear').click()
    cy.findAvailablePearsList().click()
    cy.pearIsAvailable('Second Pear')

    addTrack('Feature Track')
    cy.findAssignedPear('First Pear').click()
    cy.findTrack('Feature Track').click()
    cy.pearIsInTrack('First Pear', 'Feature Track')

    cy.lockTrack('Feature Track')
    cy.clickButton('Suggest')
    cy.pearIsInTrack('Second Pear', 'Refactor Track')

    cy.clickButton('Save')
    cy.contains('Today\'s assigned pears have been recorded!').should('be.visible')

    cy.clickButton('Reset')
    cy.pearIsAvailable('Second Pear')

    cy.unlockTrack('Feature Track')
    cy.clickButton('Reset')
    cy.pearIsAvailable('First Pear')

    cy.findAvailablePear('First Pear').click()
    cy.findTrash().click()
    cy.pearDoesNotExist('First Pear')
  })

  it('can select an anchor', () => {
    cy.fillInput('Name', teamName)
    cy.fillInput('Password', teamPassword)
    cy.clickButton('Register')

    addPear('First Pear')
    addPear('Second Pear')
    addPear('Third Pear')
    addPear('Fourth Pear')

    addTrack('Feature One')
    addTrack('Feature Two')

    cy.findAvailablePear('First Pear').click()
    cy.findTrack('Feature One').click()
    cy.pearIsInTrack('First Pear', 'Feature One')

    cy.findAvailablePear('Second Pear').click()
    cy.findTrack('Feature One').click()
    cy.pearIsInTrack('Second Pear', 'Feature One')

    cy.findAvailablePear('Third Pear').click()
    cy.findTrack('Feature Two').click()
    cy.pearIsInTrack('Third Pear', 'Feature Two')

    cy.findAvailablePear('Fourth Pear').click()
    cy.findTrack('Feature Two').click()
    cy.pearIsInTrack('Fourth Pear', 'Feature Two')

    cy.clickButton('Save')

    cy.toggleAnchor('First Pear')
    cy.toggleAnchor('Third Pear')

    cy.clickButton('Reset')

    cy.pearIsInTrack('First Pear', 'Feature One')
    cy.pearIsAvailable('Second Pear')
    cy.pearIsInTrack('Third Pear', 'Feature Two')
    cy.pearIsAvailable('Fourth Pear')

    cy.clickButton('Suggest')

    cy.pearIsInTrack('First Pear', 'Feature One')
    cy.pearIsInTrack('Second Pear', 'Feature Two')
    cy.pearIsInTrack('Third Pear', 'Feature Two')
    cy.pearIsInTrack('Fourth Pear', 'Feature One')
  })

  it('can get suggested facilitator and shuffle for someone else', () => {
    cy.fillInput('Name', teamName)
    cy.fillInput('Password', teamPassword)
    cy.clickButton('Register')

    addPear('First Pear')
    addPear('Second Pear')
    addPear('Third Pear')
    addPear('Fourth Pear')

    addTrack('Feature One')
    addTrack('Feature Two')

    cy.findAvailablePear('First Pear').click()
    cy.findTrack('Feature One').click()
    cy.pearIsInTrack('First Pear', 'Feature One')

    cy.findAvailablePear('Second Pear').click()
    cy.findTrack('Feature One').click()
    cy.pearIsInTrack('Second Pear', 'Feature One')

    cy.findAvailablePear('Third Pear').click()
    cy.findTrack('Feature Two').click()
    cy.pearIsInTrack('Third Pear', 'Feature Two')

    cy.findAvailablePear('Fourth Pear').click()
    cy.findTrack('Feature Two').click()
    cy.pearIsInTrack('Fourth Pear', 'Feature Two')

    cy.clickButton('Save')

    cy.toggleAnchor('First Pear')
    cy.toggleAnchor('Third Pear')

    cy.clickButton('Reset')

    cy.pearIsInTrack('First Pear', 'Feature One')
    cy.pearIsAvailable('Second Pear')
    cy.pearIsInTrack('Third Pear', 'Feature Two')
    cy.pearIsAvailable('Fourth Pear')

    cy.clickButton('Suggest')

    cy.pearIsInTrack('First Pear', 'Feature One')
    cy.pearIsInTrack('Second Pear', 'Feature Two')
    cy.pearIsInTrack('Third Pear', 'Feature Two')
    cy.pearIsInTrack('Fourth Pear', 'Feature One')
  })
})
