/// <reference types="cypress" />

context('Validation', () => {
  const existingTeamName = 'Existing Team'
  const teamName = 'Team Cypress'

  beforeEach(() => {
    cy.createTeam(existingTeamName)
    cy.deleteTeam(teamName)

    cy.visit('/')
  })

  function testInvalidNameValidation() {
    cy.fillInput('Create Team', existingTeamName)
    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`)

    cy.get('[name="team-name"]').clear()
    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`)
      .should('not.visible')
  }

  function addPear(pearName) {
    cy.clickLink('Add Pear')

    cy.contains('h2', 'Add Pear')

    cy.fillInput('Name', pearName)
    cy.clickButton('Add')

    cy.pearIsAvailable(pearName)

    cy.get('.phx-modal')
      .should('not.visible')
  }

  function addTrack(trackName) {
    cy.clickLink('Add Track')

    cy.contains('h2', 'Add Track')

    cy.fillInput('Name', trackName)
    cy.clickButton('Add')

    cy.trackExists(trackName)

    cy.get('.phx-modal')
      .should('not.visible')
  }

  it('redirects to root for teams that dont exist', () => {
    cy.visit('/teams/fake-team')
    cy.location('pathname').should('equal', '/')
  })

  it('create team, add pears, add tracks, and recommend pears', () => {
    testInvalidNameValidation()

    cy.fillInput('Create Team', teamName)
    cy.clickButton('Create')
    cy.contains('Congratulations, your team has been created!').should('visible')

    addPear('Second Pear')
    addPear('Second Pear')
    cy.contains(`Sorry, a Pear with the name 'Second Pear' already exists`)
      .should('visible')

    addTrack('Feature 1')
    addTrack('Feature 1')
    cy.contains(`Sorry, a track with the name 'Feature 1' already exists`)
      .should('visible')

    addTrack('Feature 2')
    cy.changeTrackName('Feature 2', 'Feature 1')
    cy.trackExists('Feature 2')
    cy.contains(`Sorry, a track with the name 'Feature 1' already exists`)
      .should('visible')
  })
})
