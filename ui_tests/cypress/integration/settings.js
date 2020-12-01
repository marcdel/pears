/// <reference types="cypress" />

import {addPear} from "../support/helpers"

const teamName = 'Team Cypress'
const newTeamName = 'Team Cypress 2'
const teamPassword = 'Cypress Password'
const newTeamPassword = 'New Cypress Password'

function registerTeam() {
  cy.visit('/teams/register')
  cy.fillInput('Name', teamName)
  cy.fillInput('Password', teamPassword)
  cy.clickButton('Register')
}

beforeEach(() => {
  cy.deleteTeam(teamName)
  cy.deleteTeam(newTeamName)
  registerTeam()
})

it('can change team name', () => {
  cy.visit('/settings')

  cy.contains('h2', /Change team name/s)
    .should('be.visible')

  cy.fillInput('Name', newTeamName)
  cy.fillInput('Current password', teamPassword)
  cy.clickButton('Change name')

  cy.contains('p', 'Team name updated successfully')
    .should('be.visible')
})

it('can change team password', () => {
  cy.visit('/settings/password')

  cy.contains('h2', /Change password/s)
    .should('be.visible')

  cy.fillInput('New password', newTeamPassword)
  cy.fillInput('Confirm new password', newTeamPassword)
  cy.fillInput('Current password', teamPassword)
  cy.clickButton('Change password')

  cy.contains('p', 'Password updated successfully')
    .should('be.visible')
})
