/// <reference types="cypress" />

import {addPear, addTrack} from "../support/helpers"

context('Full Journey', () => {
  const teamName = 'Team Cypress'

  beforeEach(() => {
    cy.deleteTeam(teamName)

    cy.visit('/')
  })

  it('create team, add pears, add tracks, and recommend pears', () => {
    cy.get('[data-cy="team-name-field"]')
      .type(teamName)
      .should('have.value', teamName)

    cy.clickButton('Create')

    cy.contains('Congratulations, your team has been created!').should('be.visible')
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
  })
})
