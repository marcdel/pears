module.exports = {
  projectId: 'x4rpwe',
  viewportWidth: 1680,
  viewportHeight: 749,
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      return require('./cypress/plugins/index.js')(on, config)
    },
    baseUrl: 'http://localhost:5000/',
    specPattern: 'cypress/e2e/**/*.{js,jsx,ts,tsx}',
  },
}
