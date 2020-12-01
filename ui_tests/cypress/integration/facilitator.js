/// <reference types="cypress" />

import {addPear} from "../support/helpers"

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

it('does not show facilitator suggestions when feature is off', () => {
  cy.toggleFlag('random_facilitator', false)

  cy.contains('p', /Today's facilitator is/s)
    .should('not.be.visible')

  addPear('First Pear')

  cy.contains('p', "Today's facilitator is First Pear")
    .should('not.be.visible')
})

it('can get suggested facilitator and shuffle for someone else', () => {
  cy.toggleFlag('random_facilitator', true)

  cy.contains('p', /Today's facilitator is/s)
    .should('not.be.visible')

  addPear('First Pear')

  cy.contains('p', "Today's facilitator is First Pear")
    .should('be.visible')

  addPear('Second Pear')

  cy.contains('p', /Today's facilitator is/s)
    .should('be.visible')

  cy.clickButton('Shuffle')

  cy.contains('p', /Today's facilitator is/s)
    .should('be.visible')
})
