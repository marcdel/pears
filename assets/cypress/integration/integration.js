/// <reference types="cypress" />

context('Actions', () => {
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

  function testInvalidPearNameValidation() {
    addPear('Second Pear')
    cy.contains(`Sorry, a Pear with the name 'Second Pear' already exists`)
      .should('visible')
  }

  function addPear(pearName) {
    cy.clickLink('Add Pear')

    cy.contains('h2', 'Add Pear')

    cy.fillInput('Name', pearName)
    cy.clickButton('Add')

    cy.pearAvailable(pearName)

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
    cy.location('pathname').should('include', '/teams/')
    cy.contains('h1', teamName)

    addPear('First Pear')
    addPear('Second Pear')

    testInvalidPearNameValidation()

    addTrack('Feature Track')

    cy.clickButton('Recommend Pears')

    cy.pearIsInTrack('First Pear', 'Feature Track')
    cy.pearIsInTrack('Second Pear', 'Feature Track')

    cy.clickButton('Record Pears')
    cy.contains('Today\'s assigned pears have been recorded!').should('visible')

    cy.removeTrack('Feature Track')
    cy.trackDoesNotExist('Feature Track')

    cy.pearAvailable('First Pear')
    cy.pearAvailable('Second Pear')

    addTrack('Refactor Track')

    cy.findAvailablePear('First Pear').click()
    cy.findTrack('Refactor Track').click()
    cy.pearIsInTrack('First Pear', 'Refactor Track')

    cy.findAvailablePear('Second Pear').click()
    cy.findTrack('Refactor Track').click()
    cy.pearIsInTrack('Second Pear', 'Refactor Track')

    cy.findAssignedPear('Second Pear').click()
    cy.get('.available-pears').click()
    cy.pearAvailable('Second Pear')

    addTrack('Feature Track')
    cy.findAssignedPear('First Pear').click()
    cy.findTrack('Feature Track').click()
    cy.pearIsInTrack('First Pear', 'Feature Track')

    cy.lockTrack('Feature Track')
    cy.clickButton('Recommend Pears')
    cy.pearIsInTrack('Second Pear', 'Refactor Track')

    cy.clickButton('Record Pears')
    cy.contains('Today\'s assigned pears have been recorded!').should('visible')
  })
})
