/// <reference types="cypress" />

const teamName = 'Team Cypress'
const teamPassword = 'Cypress Password'

function registerTeam() {
  cy.visit('/teams/register')
  cy.fillInput('Name', teamName)
  cy.fillInput('Password', teamPassword)
  cy.clickButton('Register')
}

beforeEach(() => {
  cy.deleteTeam(teamName)
  registerTeam()
})

it('step 1 defaults to incomplete and step 2 is disabled', () => {
  cy.visit('/settings/slack')

  cy.contains('h2', 'Step 1')
    .should('be.visible')

  cy.get('[alt="Add to Slack"]')
    .should('be.visible')

  cy.get(`[data-cy="step-1-complete"]`)
    .should('not.be.visible')

  cy.contains('h2', 'Step 2')
    .should('be.visible')

  cy.get(`[data-cy="step-2-complete"]`)
    .should('not.be.visible')

  cy.findByLabelText(/Select your team's channel/i)
    .should('be.disabled')

  cy.findByText(/Save channel/i)
    .should('be.disabled');

  cy.contains('h2', 'Step 3')
    .should('be.visible')

  cy.get(`[data-cy="step-3-complete"]`)
    .should('not.be.visible')

  cy.findByText(/Save slack handles/i)
    .should('be.disabled');
})
