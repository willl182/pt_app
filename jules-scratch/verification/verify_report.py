import re
from playwright.sync_api import sync_playwright, expect

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    # 1. Arrange: Go to the application.
    page.goto("http://localhost:8080")

    # Wait for the app to load by checking for the main heading
    expect(page.get_by_role("heading", name="Modulo Evaluación Estabilidad y Homogeneidad del Item de Ensayo")).to_be_visible()

    # 2. Act: Upload data using the correct file names
    # Upload homogeneity data
    with page.expect_file_chooser() as fc_info_homog:
        page.locator('label[for="datafile"] + .input-group .btn-file').click()
    file_chooser_homog = fc_info_homog.value
    file_chooser_homog.set_files("bsw_co.csv")

    # Upload stability data
    with page.expect_file_chooser() as fc_info_stab:
        page.locator('label[for="stability_datafile"] + .input-group .btn-file').click()
    file_chooser_stab = fc_info_stab.value
    file_chooser_stab.set_files("CO.csv")

    # Wait for data to be loaded by checking for the data preview table
    expect(page.locator("#raw_data_preview")).to_be_visible()

    # 3. Act: Navigate to reports
    # Dump page content to debug the locator for the "Reports" tab
    print("Dumping page HTML for debugging...")
    print(page.content())
    page.screenshot(path="jules-scratch/verification/debug_before_click.png")

    # Click on the "Reports" tab
    page.get_by_role("link", name="Reports").click()

    # The "Homogeneity and Stability Report" tab should be selected by default.

    # 4. Act: Generate report
    # Click on the "Generate Report" button within the correct module context
    page.locator("#reports_tab-homog_stab_report-generate_report").click()

    # 5. Assert: Wait for the report content to be visible and check its contents
    report_content = page.locator("#reports_tab-homog_stab_report-report_content")
    expect(report_content).to_be_visible(timeout=30000)

    # Check that reports for both levels are present
    expect(report_content.locator("h4", has_text=re.compile(r"Analysis for Level: 0-ppm"))).to_be_visible()
    expect(report_content.locator("h4", has_text=re.compile(r"Analysis for Level: 5-ppm"))).to_be_visible()

    expect(report_content.locator("img")).to_have_count(4)
    expect(report_content.locator("table")).to_have_count(4)

    # 6. Screenshot
    page.screenshot(path="jules-scratch/verification/verification.png")

    print("Verification script completed and screenshot taken.")

    browser.close()

if __name__ == "__main__":
    from playwright.sync_api import sync_playwright, expect
    with sync_playwright() as p:
        run(p)