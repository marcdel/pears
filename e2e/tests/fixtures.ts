import { test as base, expect, Page } from "@playwright/test";

/**
 * Registers a new team and returns credentials.
 * This is the canonical auth helper for internal e2e tests.
 */
async function registerTeam(page: Page) {
  const teamName = `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
  const password = "test-password-1234";

  await page.goto("/teams/register");
  await page.getByLabel("Name").fill(teamName);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Register" }).click();

  // Registration submits and redirects to the pairing board
  await page.waitForURL("/");

  return { teamName, password };
}

type SeedFixtures = {
  authenticatedPage: Page;
  teamName: string;
};

export const test = base.extend<SeedFixtures>({
  authenticatedPage: async ({ page }, use) => {
    const { teamName } = await registerTeam(page);
    // Stash team name on the page object for tests that need it
    (page as any).__teamName = teamName;
    await use(page);
  },
  teamName: async ({ authenticatedPage }, use) => {
    await use((authenticatedPage as any).__teamName);
  },
});

export { expect, registerTeam };
