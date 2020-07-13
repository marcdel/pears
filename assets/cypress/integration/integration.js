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

  afterEach(() => {
    cy.deleteTeam(teamId)
  })

  it('create team, add pears, add tracks, and recommend pairs', () => {
    cy.contains('label', /Create Team/i)

    cy.get('[name="team-name"]')
      .type(existingTeamName)
      .should('have.value', existingTeamName)
    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`)

    cy.get('[name="team-name"]').clear()
    cy.contains(`Sorry, the name "${existingTeamName}" is already taken`).should('not.exist')

    cy.get('[name="team-name"]')
      .type(teamName)
      .should('have.value', teamName)

    cy.get('button')
      .contains('Create')
      .click()

    cy.contains('Congratulations, your team has been created!')
    cy.location('pathname').should('include', '/teams/')
    cy.contains('h1', teamName)
  })
})
