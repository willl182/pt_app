from playwright.sync_api import sync_playwright, expect

def run_verification(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    try:
        # Navigate to the app with a longer timeout
        print("Navigating to the application...")
        page.goto("http://localhost:8080", timeout=60000)

        # Wait for the main title to be visible, indicating the app has loaded
        print("Waiting for application to load...")
        expect(page.get_by_role("heading", name="Modulo Evaluación Estabilidad y Homogeneidad del Item de Ensayo")).to_be_visible(timeout=30000)
        print("Application loaded.")

        # Upload Homogeneity Data
        print("Uploading homogeneity data...")
        page.locator('input[type="file"]').first.set_input_files('CO.csv')

        # Upload Stability Data
        print("Uploading stability data...")
        page.locator('input[type="file"]').last.set_input_files('CO.csv')

        # Wait for file uploads to be processed
        page.wait_for_timeout(3000)
        print("Data uploaded.")

        # Print the page's HTML to debug selector issues
        print("Dumping page HTML for debugging...")
        print(page.content())

        # Go to the Reports tab
        print("Navigating to Reports tab...")
        reports_tab_selector = 'a[data-toggle="tab"][data-value="Reports"]'
        expect(page.locator(reports_tab_selector)).to_be_visible(timeout=10000)
        page.locator(reports_tab_selector).click()
        print("Clicked on Reports tab.")

        # Generate the report
        print("Generating report...")
        page.get_by_role("button", name="Generate Report").click()

        # Wait for the report content to be visible
        print("Waiting for report content...")
        expect(page.locator("div#reports_tab-report_content")).to_be_visible(timeout=20000)
        print("Report content is visible.")

        # Take a screenshot
        page.screenshot(path="jules-scratch/verification/report_verification.png")
        print("Screenshot taken successfully.")

    except Exception as e:
        print(f"An error occurred: {e}")
        page.screenshot(path="jules-scratch/verification/error_screenshot.png")
        print("Error screenshot taken.")

    finally:
        browser.close()

with sync_playwright() as playwright:
    run_verification(playwright)