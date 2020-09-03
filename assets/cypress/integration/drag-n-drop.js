/// <reference types="cypress" />

context('Drag-n-drop', () => {
  const teamName = 'Team Cypress'

  beforeEach(() => {
    cy.deleteTeam(teamName)

    cy.visit('/')

    cy.fillInput('Create Team', teamName)
    cy.clickButton('Create')
  })

  function addPear(pearName) {
    cy.clickLink('Add Pear')

    cy.contains('h2', 'Add Pear')

    cy.fillInput('Name', pearName)
    cy.clickButton('Add')

    cy.pearIsAvailable(pearName)

    cy.get('.phx-modal')
      .should('not.be.visible')
  }

  function addTrack(trackName) {
    cy.clickLink('Add Track')

    cy.contains('h2', 'Add Track')

    cy.fillInput('Name', trackName)
    cy.clickButton('Add')

    cy.trackExists(trackName)

    cy.get('.phx-modal')
      .should('not.be.visible')
  }

  it('supports drag and drop', () => {
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
