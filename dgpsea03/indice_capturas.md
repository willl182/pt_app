# Indice tecnico de capturas DG-PSEA-03

**Fecha de captura:** 2026-06-28  
**Repositorio:** `pt_app`  
**Rama:** `main`  
**Commit base observado:** `794ceb4`  
**URL local:** `http://127.0.0.1:3838`  
**Navegador:** Chromium `/usr/bin/chromium`  
**Automatizacion:** Playwright, script `scripts/tomar_capturas.js`  
**Datos cargados:** `data/homogeneity.csv`, `data/stability.csv`, `data/summary_n4.csv`  

## Comando de ejecucion

```bash
python /home/w182/.agents/skills/webapp-testing/scripts/with_server.py \
  --server "Rscript -e \"shiny::runApp('.', host='127.0.0.1', port=3838, launch.browser=FALSE)\"" \
  --port 3838 --timeout 60 -- node dgpsea03/scripts/tomar_capturas.js
```

## Capturas generadas

| Archivo | Modulo/pantalla | Evidencia principal |
|---|---|---|
| `capturas/01_inicio_carga_datos.png` | Carga de datos | Pantalla inicial y zonas de carga CSV. |
| `capturas/02_carga_datos_estado.png` | Carga de datos | Estado posterior a cargar homogeneidad, estabilidad y consolidado. |
| `capturas/03_preprocesador_modal.png` | Preprocesador | Flujo crudos CALAIRE, intercambio con `calaire-app` y consolidacion. |
| `capturas/04_homogeneidad_vista_previa.png` | Homogeneidad/estabilidad | Vista previa, distribuciones y validacion de datos. |
| `capturas/05_homogeneidad_resultados.png` | Homogeneidad | Conclusiones, resumen, ANOVA y criterios MADe/nIQR. |
| `capturas/06_estabilidad_resultados.png` | Estabilidad | Conclusiones, resumen y criterios de estabilidad. |
| `capturas/07_incertidumbre_he.png` | Incertidumbre H/E | `u_hom`, `u_stab` y contribuciones asociadas. |
| `capturas/08_valores_atipicos.png` | Valores atipicos | Resumen de Grubbs y visualizaciones. |
| `capturas/09_valor_asignado_algoritmo_a.png` | Valor asignado | Algoritmo A ejecutado y resumen de iteraciones. |
| `capturas/10_valor_asignado_consenso.png` | Valor asignado | Valor consenso y desviaciones robustas. |
| `capturas/11_compatibilidad_metrologica.png` | Valor asignado | Compatibilidad entre referencia y consenso. |
| `capturas/12_puntajes_resumen.png` | Puntajes EA | Parametros y resumen de puntajes por participante. |
| `capturas/13_puntajes_z.png` | Puntajes EA | Tablas y graficos de puntaje `z`. |
| `capturas/14_puntajes_en.png` | Puntajes EA | Tablas y graficos de puntaje `En`. |
| `capturas/15_informe_global.png` | Informe global | Resumen global, parametros y resultados. |
| `capturas/16_participantes.png` | Participantes | Resultados detallados por participante. |
| `capturas/17_generacion_informes.png` | Generacion de informes | Configuracion de identificacion, metrica, metodo y descarga Word. |

## Resultado

La automatizacion finalizo con codigo de salida `0`. El documento Word `DG-PSEA-03 Aplicativo pt_app.docx` contiene las 17 imagenes embebidas.
