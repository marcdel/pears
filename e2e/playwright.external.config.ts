import { defineConfig } from "@playwright/test";
import baseConfig from "./playwright.config";

const specDir = process.env.PEARS_SPEC_DIR;
if (!specDir) {
  throw new Error("PEARS_SPEC_DIR must be set to run external specs");
}

export default defineConfig({
  ...baseConfig,
  testDir: specDir,
});
