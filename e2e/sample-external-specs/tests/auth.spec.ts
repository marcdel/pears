/**
 * External spec: Authentication flows
 *
 * Self-contained — does not import from the Pears codebase.
 * Validates auth behavior through the running application only.
 */
import { test, expect, Page } from "@playwright/test";

function uniqueTeamName() {
  return `spec-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

async function registerTeam(page: Page) {
  const teamName = uniqueTeamName();
  const password = "spec-password-1234";

  await page.goto("/teams/register");
  await page.getByLabel("Name").fill(teamName);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Register" }).click();
  await page.waitForURL("/");

  return { teamName, password };
}

test.describe("Authentication", () => {
  test("registers a new team and reaches the pairing board", async ({
    page,
  }) => {
    await registerTeam(page);
    await expect(page).toHaveURL("/");
    await expect(
      page.locator('[data-cy="available-pears-list"]')
    ).toBeVisible();
  });

  test("logs in with existing credentials", async ({ page }) => {
    const { teamName, password } = await registerTeam(page);

    // Log out
    await page.context().clearCookies();

    // Log back in
    await page.goto("/teams/log_in");
    await page.getByLabel("Name").fill(teamName);
    await page.getByLabel("Password").fill(password);
    await page.getByRole("button", { name: "Log in" }).click();

    await expect(page).toHaveURL("/");
  });

  test("rejects invalid credentials", async ({ page }) => {
    await page.goto("/teams/log_in");
    await page.getByLabel("Name").fill("nonexistent-team");
    await page.getByLabel("Password").fill("wrong-password");
    await page.getByRole("button", { name: "Log in" }).click();

    // Should show error and stay on login page
    await expect(page.getByText("Invalid name or password")).toBeVisible();
  });

  test("redirects unauthenticated users to login", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/teams\/log_in/);
  });
});
