import { test, expect, registerTeam } from "./fixtures";

test.describe("Smoke tests", () => {
  test("can register a new team and see the pairing board", async ({
    page,
  }) => {
    const { teamName } = await registerTeam(page);

    // Should be on the pairing board
    await expect(page).toHaveURL("/");
    await expect(
      page.locator('[data-cy="available-pears-list"]')
    ).toBeVisible();
  });

  test("unauthenticated users are redirected to login", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/teams\/log_in/);
  });

  test("can log in with existing credentials", async ({ page }) => {
    // First register a team
    const { teamName, password } = await registerTeam(page);

    // Log out by clearing cookies
    await page.context().clearCookies();

    // Now log in
    await page.goto("/teams/log_in");
    await page.getByLabel("Name").fill(teamName);
    await page.getByLabel("Password").fill(password);
    await page.getByRole("button", { name: "Log in" }).click();

    await expect(page).toHaveURL("/");
    await expect(
      page.locator('[data-cy="available-pears-list"]')
    ).toBeVisible();
  });
});
