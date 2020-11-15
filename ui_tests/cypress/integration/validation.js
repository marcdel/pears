/// <reference types="cypress" />

import {addPear, addTrack} from "../support/helpers"

context('Validation', () => {
  const existingTeamName = 'Existing Team'
  const teamName = 'Team Cypress'
  const teamPassword = 'Cypress Password'

  beforeEach(() => {
    cy.createTeam(existingTeamName)
    cy.deleteTeam(teamName)

    cy.visit('/')
  })

  function testInvalidNameValidation() {
    cy.fillInput('Name', existingTeamName)
    cy.fillInput('Password', teamPassword)

    cy.clickButton(/register/i)

    cy.get(`[phx-feedback-for="team_name"]`)
      .should('have.text', 'has already been taken')

    cy.clearInput('Name')
  }

  it('redirects to root for teams that dont exist', () => {
    cy.visit('/teams/fake-team')
    cy.location('pathname').should('equal', '/teams/log_in')
  })

  it('create team, add pears, add tracks, and recommend pears', () => {
    testInvalidNameValidation()

    cy.fillInput('Name', teamName)
    cy.fillInput('Password', teamPassword)

    cy.clickButton(/register/i)
    cy.contains('Team created successfully.').should('be.visible')

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
