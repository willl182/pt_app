from playwright.sync_api import sync_playwright, expect

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    try:
        # Navigate to the app
        page.goto("http://0.0.0.0:8080")

        # Wait for the main layout to be visible
        expect(page.locator("#main_nav")).to_be_visible()

        # Take a screenshot of the initial state
        page.screenshot(path="jules-scratch/verification/01_initial_state.png")

        # Interact with the inputs
        # Click the dropdown to open it
        page.locator("div.selectize-input").first.click()
        # Click the option for 'co'
        page.locator("div.selectize-dropdown-content div[data-value='co']").click()


        # Wait for the level selector to appear and have options
        expect(page.locator("#target_level")).to_be_visible()
        expect(page.locator("#target_level option")).to_have_count(3) # Expecting 3 levels for 'co'

        # Select a level (e.g., '1')
        page.select_option("#target_level", "1")

        # Click the run analysis button
        page.get_by_role("button", name="Ejecutar (Run Analysis)").click()

        # Wait for the conclusion to be visible
        expect(page.locator("#homog_conclusion .alert-success")).to_be_visible()

        # Take a screenshot of the results
        page.screenshot(path="jules-scratch/verification/02_analysis_results.png")

        # Switch to the 'Stability Asessment' tab
        page.get_by_role("tab", name="Stability Asessment").click()

        # Wait for the stability conclusion to be visible
        expect(page.locator("#homog_conclusion_stability .alert-success")).to_be_visible()

        # Take a screenshot of the stability results
        page.screenshot(path="jules-scratch/verification/03_stability_results.png")


    finally:
        # Close the browser
        browser.close()

with sync_playwright() as playwright:
    run(playwright)