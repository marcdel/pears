Run end-to-end Playwright specs against the Pears application.

## What to do

1. Run the e2e runner script from the project root:
   ```
   ./bin/run_e2e.sh
   ```
   If the user provided arguments like `PEARS_SPEC_REPO_URL` or `PEARS_SPEC_DIR`, set them as environment variables:
   ```
   PEARS_SPEC_DIR=/path/to/specs ./bin/run_e2e.sh
   ```

2. Parse the output and report:
   - Total tests run (internal + external)
   - Pass/fail counts
   - For any failures, include the test name and error message

3. If there are failures, check the Playwright HTML report at `e2e/playwright-report/` for detailed traces and screenshots.

4. Summarize results concisely. If all tests pass, say so. If tests fail, explain what failed and suggest next steps.

## Environment variables

- `PEARS_SPEC_REPO_URL` - Git URL of an external spec repo to clone and run
- `PEARS_SPEC_REPO_REF` - Branch/tag to checkout (default: main)
- `PEARS_SPEC_DIR` - Local path to external specs directory (overrides repo clone)
- `SKIP_INTERNAL` - Set to skip running internal smoke tests
