/// <reference types="cypress" />

import {addPear, addTrack} from "../support/helpers"

context('Drag-n-drop', () => {
  const teamName = 'Team Cypress'

  beforeEach(() => {
    cy.deleteTeam(teamName)

    cy.visit('/')

    cy.get('[data-cy="team-name-field"]')
      .type(teamName)
      .should('have.value', teamName)

    cy.clickButton('Create')
  })

  xit('supports drag and drop', () => {
    addPear('First Pear')
    addPear('Second Pear')
    addTrack('Feature 1')
    addTrack('Feature 2')

    cy.dragPearToTrack('First Pear', 'Feature 1')
    cy.pearIsInTrack('First Pear', 'Feature 1')

    cy.dragPearToTrack('Second Pear', 'Feature 1')
    cy.pearIsInTrack('Second Pear', 'Feature 1')

    cy.dragPearFromTrackToTrack('Second Pear', 'Feature 1', 'Feature 2')
    cy.pearIsInTrack('Second Pear', 'Feature 2')

    cy.dragPearToUnassigned('First Pear')
    cy.pearIsAvailable('First Pear')
  })
})
