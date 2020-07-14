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
      .should('not.exist')
  }

  function addPear(pearName) {
    cy.clickLink('Add Pear')

    cy.contains('h2', 'Add Pear')

    cy.fillInput('Name', pearName)
    cy.clickButton('Add')

    cy.contains('section', 'Available Pears')
      .within((section) => section.find('li', pearName))
  }

  it('create team, add pears, add tracks, and recommend pairs', () => {
    testInvalidNameValidation()

    cy.fillInput('Create Team', teamName)

    cy.clickButton('Create')

    cy.contains('Congratulations, your team has been created!')
    cy.location('pathname').should('include', '/teams/')
    cy.contains('h1', teamName)

    addPear('First Pear')
    addPear('Second Pear')
  })
})
