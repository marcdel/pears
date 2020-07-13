/// <reference types="cypress" />
import {generateName} from '../support/generateName'

context('Actions', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  it('create team, add pears, add tracks, and recommend pairs', () => {
    cy.contains('label', /Create Team/i)

    const teamName = generateName()
    console.log({teamName})

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
