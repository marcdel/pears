/**
 * External spec: Pairing board interactions
 *
 * Self-contained — does not import from the Pears codebase.
 * Validates pairing board behavior through the running application only.
 */
import { test, expect, Page } from "@playwright/test";

function uniqueTeamName() {
  return `spec-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

async function registerAndLogin(page: Page) {
  const teamName = uniqueTeamName();
  const password = "spec-password-1234";

  await page.goto("/teams/register");
  await page.getByLabel("Name").fill(teamName);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Register" }).click();
  await page.waitForURL("/");

  return { teamName, password };
}

test.describe("Pairing Board", () => {
  test.beforeEach(async ({ page }) => {
    await registerAndLogin(page);
  });

  test("renders the pairing board after login", async ({ page }) => {
    await expect(
      page.locator('[data-cy="available-pears-list"]')
    ).toBeVisible();
  });

  test("can add a new pear", async ({ page }) => {
    const pearName = `Pear-${Date.now()}`;

    await page.locator('[data-cy="add-pear-input"]').fill(pearName);
    await page.locator('[data-cy="add-pear-input"]').press("Enter");

    await expect(
      page.locator(`[data-cy="available-pear ${pearName}"]`)
    ).toBeVisible();
  });

  test("can add a new track", async ({ page }) => {
    const trackName = `Track-${Date.now()}`;

    await page.locator('[data-cy="add-track-input"]').fill(trackName);
    await page.locator('[data-cy="add-track-input"]').press("Enter");

    await expect(
      page.locator(`[data-cy="track ${trackName}"]`)
    ).toBeVisible();
  });
});
