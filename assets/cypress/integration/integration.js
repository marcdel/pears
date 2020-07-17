/// <reference types="cypress" />

context('Actions', () => {
  const existingTeamName = 'Existing Team'
  const teamName = 'Team Cypress'
  const teamId = 'team-cypress'

  beforeEach(() => {
    cy.createTeam(existingTeamName)
    cy.deleteTeam(teamId)

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

  it('create team, add pears, add tracks, and recommend pairs', () => {
    testInvalidNameValidation()

    cy.fillInput('Create Team', teamName)

    cy.clickButton('Create')

    cy.contains('Congratulations, your team has been created!')
    cy.location('pathname').should('include', '/teams/')
    cy.contains('h1', teamName)

    addPear('First Pear')
    addPear('Second Pear')

    addTrack('Feature Track')

    cy.clickButton('Recommend Pairs')

    cy.contains('Feature Track').parent()
      .should('contain', 'First Pear')
      .and('contain', 'Second Pear')

    cy.contains('Feature Track').find('a').click()

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
  })
})
