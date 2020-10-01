/// <reference types="cypress" />

import {addPear, addTrack} from "../support/helpers"

context('Validation', () => {
  const existingTeamName = 'Existing Team'
  const teamName = 'Team Cypress'

  beforeEach(() => {
    cy.createTeam(existingTeamName)
    cy.deleteTeam(teamName)

    cy.visit('/')
  })

  function testInvalidNameValidation() {
    cy.get('[data-cy="team-name-field"]')
      .type(existingTeamName)
      .should('have.value', existingTeamName)

    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`)

    cy.get('[name="team-name"]').clear()
    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`)
      .should('not.be.visible')
  }

  it('redirects to root for teams that dont exist', () => {
    cy.visit('/teams/fake-team')
    cy.location('pathname').should('equal', '/')
  })

  it('create team, add pears, add tracks, and recommend pears', () => {
    testInvalidNameValidation()

    cy.get('[data-cy="team-name-field"]')
      .type(teamName)
      .should('have.value', teamName)

    cy.clickButton('Create')
    cy.contains('Congratulations, your team has been created!').should('be.visible')

    addPear('Second Pear')
    addPear('Second Pear')
    cy.contains(`Sorry, a Pear with the name 'Second Pear' already exists`)
      .should('be.visible')

    addTrack('Feature 1')
    addTrack('Feature 1')
    cy.contains(`Sorry, a track with the name 'Feature 1' already exists`)
      .should('be.visible')

    addTrack('Feature 2')
    cy.changeTrackName('Feature 2', 'Feature 1')
    cy.trackExists('Feature 2')
    cy.contains(`Sorry, a track with the name 'Feature 1' already exists`)
      .should('be.visible')
  })
})
