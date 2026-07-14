const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..', '..');
const evidenceDir = path.join(root, 'Entregables_pt_app', '00_evidencia_visual');
const capturesDir = path.join(evidenceDir, 'capturas');
const demoDir = path.join(evidenceDir, 'datos_demo');
const baseUrl = process.env.PT_APP_URL || 'http://127.0.0.1:3838';
const commit = process.env.PT_APP_COMMIT || runGit('rev-parse HEAD');
const capturedAt = new Date().toISOString();
const browserPath = process.env.CHROMIUM_PATH || '/usr/bin/chromium';
const gitChanges = runGit('status --porcelain').split('\n').filter(Boolean);
const desktopViewport = { width: 1440, height: 1200 };
const mobileViewport = { width: 1024, height: 768 };

const files = {
  homogeneity: path.join(demoDir, 'homogeneity_demo.csv'),
  stability: path.join(demoDir, 'stability_demo.csv'),
  summary: path.join(demoDir, 'summary_demo.csv'),
  invalid: path.join(demoDir, 'archivo_invalido.csv'),
};

const consumers = {
  'CAP-01': 'E01;E05;E06', 'CAP-02': 'E05;E06;E08',
  'CAP-03': 'E05;E06', 'CAP-04': 'E03;E05;E06',
  'CAP-05': 'E03;E06;E07;E09', 'CAP-06': 'E03;E06;E07;E09',
  'CAP-07': 'E03;E06;E09', 'CAP-08': 'E03;E06;E07',
  'CAP-09': 'E02;E03;E06;E09', 'CAP-10': 'E03;E06;E07;E09',
  'CAP-11': 'E03;E06;E07;E09', 'CAP-12': 'E04;E06;E07;E09',
  'CAP-13': 'E04;E06;E07', 'CAP-14': 'E04;E06;E07',
  'CAP-15': 'E06;E07;E09', 'CAP-16': 'E06;E07',
  'CAP-17': 'E06;E08;E09', 'CAP-18': 'E06;E08',
  'CAP-19': 'E05;E06;E08',
};

const records = [];
const diagnostics = [];

function collectDiagnostics(page) {
  page.on('pageerror', (error) =>
    diagnostics.push(`pageerror: ${error.stack || error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') {
      const location = message.location();
      diagnostics.push(
        `console: ${message.text()} (${location.url || 'sin URL'}:${location.lineNumber || 0})`,
      );
    }
  });
}

function runGit(args) {
  return require('child_process')
    .execFileSync('git', args.split(' '), { cwd: root, encoding: 'utf8' })
    .trim();
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function csv(value) {
  const string = String(value ?? '');
  return /[",\n]/.test(string) ? `"${string.replaceAll('"', '""')}"` : string;
}

async function settle(page) {
  await page.waitForLoadState('domcontentloaded');
  await page.locator('.shiny-busy').waitFor({ state: 'hidden', timeout: 30000 })
    .catch(() => {});
  await page.waitForFunction(() => document.fonts.status === 'loaded');
}

async function waitForVisibleText(page, expected, timeout = 30000) {
  await page.waitForFunction((text) => {
    const elements = document.querySelectorAll('body *');
    return [...elements].some((element) =>
      element.textContent.includes(text) &&
      element.getClientRects().length > 0,
    );
  }, expected, { timeout });
}

async function navigate(page, value, expectedText) {
  await page.locator(`#main_nav a[data-value="${value}"]`).click();
  if (expectedText) {
    await waitForVisibleText(page, expectedText);
  }
  await settle(page);
}

async function selectTab(page, tabsetId, label, expectedText) {
  await page.locator(`#${tabsetId} a`).filter({ hasText: label }).first().click();
  await waitForVisibleText(page, expectedText);
  await settle(page);
}

async function capture(page, id, slug, title, action, expected, fullPage = true) {
  await settle(page);
  await waitForVisibleText(page, expected);
  const filename = `${id}_${slug}.png`;
  const destination = path.join(capturesDir, filename);
  await page.screenshot({ path: destination, fullPage });
  records.push({
    id, title, action, expected, filename: `capturas/${filename}`,
    sha256: sha256(destination), capturedAt, commit,
    viewport: `${page.viewportSize().width}x${page.viewportSize().height}`,
    data: id === 'CAP-18' ? 'archivo_invalido.csv' :
      'homogeneity_demo.csv;stability_demo.csv;summary_demo.csv',
    consumers: consumers[id],
  });
}

function writeOutputs() {
  const headers = [
    'id', 'titulo', 'accion_previa', 'estado_esperado', 'archivo', 'sha256',
    'fecha_utc', 'commit', 'viewport', 'datos_demo', 'documentos_consumidores',
  ];
  const rows = records.map((record) => [
    record.id, record.title, record.action, record.expected, record.filename,
    record.sha256, record.capturedAt, record.commit, record.viewport,
    record.data, record.consumers,
  ].map(csv).join(','));
  fs.writeFileSync(
    path.join(evidenceDir, 'indice_capturas.csv'),
    `${headers.join(',')}\n${rows.join('\n')}\n`,
  );

  const markdownRows = records.map((record) =>
    `| ${record.id} | ${record.title} | \`${record.filename}\` | ` +
    `\`${record.sha256}\` | ${record.viewport} | ${record.consumers} |`,
  );
  const markdown = `# Índice de evidencia visual reproducible\n\n` +
    `**Fecha UTC:** ${capturedAt}\n\n**Commit:** \`${commit}\`\n\n` +
    `**Navegador:** Chromium del sistema mediante Playwright 1.61.1\n\n` +
    `**Datos:** copias no sensibles y congeladas en \`datos_demo/\`\n\n` +
    `## Reproducción\n\n\`\`\`bash\n` +
    `npm ci\n` +
    `scripts/documentacion/ejecutar_capturas.sh\n` +
    `\`\`\`\n\n` +
    `## Capturas\n\n| ID | Pantalla | Archivo | SHA-256 | Viewport | Consumidores |\n` +
    `|---|---|---|---|---|---|\n${markdownRows.join('\n')}\n\n` +
    `## Criterios de control\n\n` +
    `- Cada captura exige contenido semántico visible antes de guardarse.\n` +
    `- La ejecución falla ante errores de página o consola no reconocidos.\n` +
    `- El registro conserva incluso diagnósticos conocidos no bloqueantes.\n` +
    `- Los nombres, hashes, fecha, commit, resolución y datos quedan registrados.\n` +
    `- CAP-19 usa 1024×768; las demás capturas usan 1440×1200.\n\n` +
    `## Diagnósticos aceptados\n\n` +
    `El JSON conserva un 404 de favicon y el error \`adjustWidth\` que DT emite ` +
    `al redimensionar una tabla oculta. No alteran contenido ni cálculos; cualquier ` +
    `otro diagnóstico hace fallar la corrida. Su eliminación queda como riesgo ` +
    `técnico residual para una fase de mantenimiento.\n`;
  fs.writeFileSync(path.join(evidenceDir, 'indice_capturas.md'), markdown);

  const execution = {
    status: 'ok', capturedAt, commit, baseUrl, browserPath,
    playwright: require('playwright/package.json').version,
    captures: records.length,
    workingTreeChangesAtStart: gitChanges,
    dataHashes: Object.fromEntries(
      Object.entries(files).map(([key, file]) => [key, sha256(file)]),
    ),
    acceptedDiagnostics: diagnostics.filter((item) =>
      item.includes('favicon.ico') ||
      item.includes('ResizeObserver') ||
      (item.includes('datatables-binding') && item.includes('adjustWidth')),
    ),
    diagnosticAcceptance: [
      'favicon.ico 404 no afecta contenido ni operación.',
      'DataTables adjustWidth ocurre al redimensionar una tabla oculta; no es visible en la captura ni altera datos.',
    ],
    diagnostics,
  };
  fs.writeFileSync(
    path.join(evidenceDir, 'registro_ejecucion.json'),
    `${JSON.stringify(execution, null, 2)}\n`,
  );
}

(async () => {
  fs.mkdirSync(capturesDir, { recursive: true });
  for (const file of Object.values(files)) {
    if (!fs.existsSync(file)) throw new Error(`Falta dato de demostración: ${file}`);
  }

  const browser = await chromium.launch({
    headless: true,
    executablePath: browserPath,
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage({ viewport: desktopViewport });
  collectDiagnostics(page);

  try {
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.getByText('Aplicativo para Evaluación', { exact: false })
      .first().waitFor({ timeout: 60000 });
    await capture(page, 'CAP-01', 'inicio_carga', 'Inicio y carga',
      'Abrir la aplicación', 'Carga Manual de Archivos de Datos');

    await page.locator('#hom_file').setInputFiles(files.homogeneity);
    await page.locator('#stab_file').setInputFiles(files.stability);
    await page.locator('#summary_files').setInputFiles(files.summary);
    await page.getByText('Homogeneidad:', { exact: false }).waitFor({ timeout: 30000 });
    await page.getByText('Resumen: 1 archivo', { exact: false }).waitFor({ timeout: 30000 });
    await capture(page, 'CAP-02', 'carga_valida', 'Carga válida',
      'Cargar los tres CSV de demostración', 'Estado de los archivos');

    await page.locator('#open_preprocessing_workflow').click();
    await page.getByText('Preprocesador de datos', { exact: false }).waitFor();
    await capture(page, 'CAP-03', 'preprocesador', 'Preprocesador',
      'Abrir el preprocesador', 'Generar ronda completa');
    await page.getByRole('button', { name: 'Cerrar' }).click();

    await navigate(page, 'analisis_hom_estab', 'Ejecutar análisis');
    await capture(page, 'CAP-04', 'homogeneidad_previa', 'Homogeneidad previa',
      'Abrir análisis antes de ejecutarlo', 'Seleccionar nivel PT');
    await page.locator('#run_analysis').click();
    await selectTab(page, 'analysis_tabs', 'Evaluación de homogeneidad',
      'Resumen del Estudio');
    await capture(page, 'CAP-05', 'homogeneidad_resultado',
      'Homogeneidad resultado', 'Ejecutar y abrir evaluación de homogeneidad',
      'Cálculos Intermedios ANOVA');
    await selectTab(page, 'analysis_tabs', 'Evaluación de estabilidad',
      'Datos de Estabilidad');
    await capture(page, 'CAP-06', 'estabilidad_resultado',
      'Estabilidad resultado', 'Abrir evaluación de estabilidad',
      'Conclusión (Método MADe)');
    await selectTab(page, 'analysis_tabs', 'Contribuciones a la incertidumbre',
      'Resumen Incertidumbre por Homogeneidad');
    await capture(page, 'CAP-07', 'incertidumbre_he', 'Incertidumbre H/E',
      'Abrir contribuciones a la incertidumbre',
      'Resumen Incertidumbre por Estabilidad');

    await navigate(page, 'valores_atipicos', 'Resumen de valores atípicos');
    await capture(page, 'CAP-08', 'valores_atipicos', 'Valores atípicos',
      'Abrir valores atípicos', 'Visualización de Datos de Participantes');

    await navigate(page, 'valor_asignado', 'Calcular Algoritmo A');
    await page.locator('#algoA_run').click();
    await page.getByText('Resumen de Iteraciones', { exact: false }).waitFor({ timeout: 30000 });
    await capture(page, 'CAP-09', 'algoritmo_a', 'Algoritmo A',
      'Calcular Algoritmo A', 'Detalle por Participante por Iteración');
    await page.locator('#consensus_run').click();
    await selectTab(page, 'assigned_value_tabs', 'Valor consenso',
      'Resumen del Valor Consenso');
    await capture(page, 'CAP-10', 'valor_consenso', 'Valor consenso',
      'Calcular y abrir valor consenso', 'Datos de participantes');
    await page.locator('#run_metrological_compatibility').click();
    await selectTab(page, 'assigned_value_tabs', 'Compatibilidad Metrológica',
      'Diferencias entre Valor de Referencia y Consenso');
    await capture(page, 'CAP-11', 'compatibilidad_metrologica',
      'Compatibilidad metrológica', 'Calcular y abrir compatibilidad',
      'Diferencias entre Valor de Referencia y Consenso');

    await navigate(page, 'puntajes_pt', 'Calcular puntajes');
    await page.locator('#scores_run').click();
    await page.getByText('Resumen de puntajes por participante', { exact: false })
      .waitFor({ timeout: 40000 });
    await capture(page, 'CAP-12', 'puntajes_resumen', 'Resumen de puntajes',
      'Calcular puntajes', 'Resumen de evaluación de puntajes');
    await selectTab(page, 'scores_tabs', "Puntajes Z'", "Puntajes Z'");
    await capture(page, 'CAP-13', 'puntajes_zprima', "Puntajes z y z'",
      "Abrir puntajes Z'", "Puntajes Z'", false);
    await selectTab(page, 'scores_tabs', 'Puntajes Z', 'Puntajes Z');
    await capture(page, 'CAP-13', 'puntajes_z', "Puntajes z y z'",
      'Abrir puntajes Z', 'Puntajes Z', false);
    await selectTab(page, 'scores_tabs', 'Puntajes Zeta', 'Puntajes Zeta');
    await capture(page, 'CAP-14', 'puntajes_zeta', 'Puntajes zeta y En',
      'Abrir puntajes Zeta', 'Puntajes Zeta', false);
    await selectTab(page, 'scores_tabs', 'Puntajes En', 'Puntajes En');
    await capture(page, 'CAP-14', 'puntajes_en', 'Puntajes zeta y En',
      'Abrir puntajes En', 'Puntajes En', false);

    await navigate(page, 'informe_global', 'Resumen global');
    await capture(page, 'CAP-15', 'informe_global', 'Informe global',
      'Abrir informe global después de calcular puntajes', 'Resumen de evaluaciones');
    await navigate(page, 'participantes', 'Resumen detallado por participante');
    await page.locator('#participants_level').waitFor({
      state: 'attached', timeout: 30000,
    });
    await page.locator('#scores_participants_tabs a').first()
      .waitFor({ state: 'visible', timeout: 30000 });
    await page.locator('[id^="participant_table_"] table tbody tr').first()
      .waitFor({ state: 'visible', timeout: 40000 });
    await capture(page, 'CAP-16', 'participantes', 'Participantes',
      'Abrir consulta por participante y esperar sus resultados', 'Resumen',
      false);
    await navigate(page, 'generacion_informes', 'Generación de Informe Final');
    await capture(page, 'CAP-17', 'generacion_informes', 'Generación de informes',
      'Abrir generación de informes', 'Descargar informe');

    await navigate(page, 'carga_datos', 'Carga Manual de Archivos de Datos');
    await page.locator('#hom_file').setInputFiles(files.invalid);
    await page.getByText("debe contener las columnas 'value'", { exact: false })
      .first().waitFor({ timeout: 30000 });
    await capture(page, 'CAP-18', 'error_archivo', 'Error de archivo',
      'Cargar CSV sin columnas requeridas', "debe contener las columnas 'value'");

    const mobilePage = await browser.newPage({ viewport: mobileViewport });
    collectDiagnostics(mobilePage);
    await mobilePage.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await mobilePage.getByText('Aplicativo para Evaluación', { exact: false })
      .first().waitFor({ timeout: 60000 });
    await mobilePage.locator('#hom_file').setInputFiles(files.homogeneity);
    await mobilePage.locator('#stab_file').setInputFiles(files.stability);
    await mobilePage.locator('#summary_files').setInputFiles(files.summary);
    await mobilePage.getByText('Resumen: 1 archivo', { exact: false })
      .waitFor({ timeout: 30000 });
    await navigate(mobilePage, 'puntajes_pt', 'Calcular puntajes');
    await mobilePage.locator('#scores_run').click();
    await waitForVisibleText(mobilePage, 'Resumen de puntajes por participante', 40000);
    await navigate(mobilePage, 'generacion_informes', 'Generación de Informe Final');
    await capture(mobilePage, 'CAP-19', 'resolucion_menor', 'Vista en resolución menor',
      'Cargar datos válidos, calcular puntajes y usar viewport 1024x768',
      'Descargar informe');
    await mobilePage.close();

    const fatalDiagnostics = diagnostics.filter((item) =>
      !item.includes('favicon.ico') &&
      !item.includes('ResizeObserver') &&
      !(item.includes('datatables-binding') && item.includes('adjustWidth')),
    );
    if (fatalDiagnostics.length > 0) {
      throw new Error(`Errores del navegador: ${fatalDiagnostics.join(' | ')}`);
    }
    writeOutputs();
    console.log(`OK: ${records.length} capturas en ${capturesDir}`);
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error.stack || error.message);
  process.exitCode = 1;
});
