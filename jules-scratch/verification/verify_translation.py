from playwright.sync_api import Page, expect
import time

def test_spanish_translation(page: Page):
    """
    This test verifies that the application is displayed in Spanish.
    """
    # 1. Navigate to the app
    page.goto("http://127.0.0.1:8123")

    # 2. Wait for the page to load
    page.wait_for_load_state("networkidle")
    time.sleep(5) # Extra wait for safety

    # 3. Verify the title is in Spanish
    expect(page.locator("h2.title")).to_have_text("Evaluación de Homogeneidad y Estabilidad para Ítems de EP")

    # 4. Take a screenshot
    page.screenshot(path="jules-scratch/verification/spanish_translation.png")