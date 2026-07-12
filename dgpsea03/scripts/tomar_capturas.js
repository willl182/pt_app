const { chromium } = require('playwright');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const out = path.join(root, 'dgpsea03', 'capturas');
const url = 'http://127.0.0.1:3838';

/*
Run from repository root:
python /home/w182/.agents/skills/webapp-testing/scripts/with_server.py \
  --server "Rscript -e \"shiny::runApp('.', host='127.0.0.1', port=3838, launch.browser=FALSE)\"" \
  --port 3838 --timeout 60 -- node dgpsea03/scripts/tomar_capturas.js
*/

async function shot(page, name) {
  await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(out, name), fullPage: true });
}

async function clickText(page, text) {
  await page.getByText(text, { exact: false }).first().click();
  await page.waitForTimeout(800);
}

async function expectText(page, text) {
  await page.getByText(text, { exact: false }).first().waitFor({ timeout: 20000 });
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: '/usr/bin/chromium',
    args: ['--no-sandbox'],
  });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1200 } });
  await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForSelector('text=Aplicativo para Evaluación', { timeout: 60000 });

  await shot(page, '01_inicio_carga_datos.png');

  await page.locator('input#hom_file').setInputFiles(path.join(root, 'data', 'homogeneity.csv'));
  await page.locator('input#stab_file').setInputFiles(path.join(root, 'data', 'stability.csv'));
  await page.locator('input#summary_files').setInputFiles(path.join(root, 'data', 'summary_n4.csv'));
  await page.waitForTimeout(2500);
  await shot(page, '02_carga_datos_estado.png');

  await page.getByRole('button', { name: /Preprocesador/ }).click();
  await page.waitForSelector('text=Preprocesador de datos', { timeout: 10000 });
  await shot(page, '03_preprocesador_modal.png');
  await page.getByRole('button', { name: 'Cerrar' }).click();
  await page.waitForTimeout(800);

  await clickText(page, 'Análisis de homogeneidad');
  await page.getByRole('button', { name: 'Ejecutar' }).click();
  await page.waitForTimeout(2500);
  await shot(page, '04_homogeneidad_vista_previa.png');
  await clickText(page, 'Evaluación de homogeneidad');
  await shot(page, '05_homogeneidad_resultados.png');
  await clickText(page, 'Evaluación de estabilidad');
  await shot(page, '06_estabilidad_resultados.png');
  await clickText(page, 'Contribuciones a la incertidumbre');
  await shot(page, '07_incertidumbre_he.png');

  await clickText(page, 'Valores Atípicos');
  await shot(page, '08_valores_atipicos.png');

  await clickText(page, 'Valor asignado');
  await clickText(page, 'Calcular Algoritmo A');
  await expectText(page, 'Resumen de Iteraciones');
  await clickText(page, 'Calcular valores consenso');
  await clickText(page, 'Calcular Compatibilidad');
  await page.waitForTimeout(3000);
  await shot(page, '09_valor_asignado_algoritmo_a.png');
  await clickText(page, 'Valor consenso');
  await expectText(page, 'Resumen del Valor Consenso');
  await shot(page, '10_valor_asignado_consenso.png');
  await clickText(page, 'Compatibilidad Metrológica');
  await expectText(page, 'Diferencias entre Valor de Referencia y Consenso');
  await shot(page, '11_compatibilidad_metrologica.png');

  await clickText(page, 'Puntajes EA');
  await clickText(page, 'Calcular puntajes');
  await expectText(page, 'Resumen de puntajes por participante');
  await page.waitForTimeout(3500);
  await shot(page, '12_puntajes_resumen.png');
  await clickText(page, 'Puntajes Z');
  await shot(page, '13_puntajes_z.png');
  await clickText(page, 'Puntajes En');
  await shot(page, '14_puntajes_en.png');

  await clickText(page, 'Informe global');
  await shot(page, '15_informe_global.png');

  await clickText(page, 'Participantes');
  await shot(page, '16_participantes.png');

  await clickText(page, 'Generación de informes');
  await shot(page, '17_generacion_informes.png');

  await browser.close();
})();
