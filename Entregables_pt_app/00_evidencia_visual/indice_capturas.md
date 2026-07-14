# Índice de evidencia visual reproducible

**Fecha UTC:** 2026-07-14T17:12:15.340Z

**Commit:** `9aea5182618035efa10e8e1aa6fbad8e6f27283b`

**Navegador:** Chromium del sistema mediante Playwright 1.61.1

**Datos:** copias no sensibles y congeladas en `datos_demo/`

## Reproducción

```bash
npm ci
scripts/documentacion/ejecutar_capturas.sh
```

## Capturas

| ID | Pantalla | Archivo | SHA-256 | Viewport | Consumidores |
|---|---|---|---|---|---|
| CAP-01 | Inicio y carga | `capturas/CAP-01_inicio_carga.png` | `d5f1a775dbed606da22a93ceb09c86bc57ff59aebb35a394dd5760e4ef0284ca` | 1440x1200 | E01;E05;E06 |
| CAP-02 | Carga válida | `capturas/CAP-02_carga_valida.png` | `0f332b8977686fd794332bdbc3b6dee0508a58737ff5ed5edb9c1ee3427378d6` | 1440x1200 | E05;E06;E08 |
| CAP-03 | Preprocesador | `capturas/CAP-03_preprocesador.png` | `01422d583288809f833019e07b8a1c8729db9efc942e68e4a63c2954ae493af1` | 1440x1200 | E05;E06 |
| CAP-04 | Homogeneidad previa | `capturas/CAP-04_homogeneidad_previa.png` | `09853b207d4d3672d80786317472d83d483ec037d3236c0cf3eb05648f07f527` | 1440x1200 | E03;E05;E06 |
| CAP-05 | Homogeneidad resultado | `capturas/CAP-05_homogeneidad_resultado.png` | `228c7f3ee8baeeb27b6a555c55a6763a840680339d1867278c8987e39a959206` | 1440x1200 | E03;E06;E07;E09 |
| CAP-06 | Estabilidad resultado | `capturas/CAP-06_estabilidad_resultado.png` | `a8578d603903c3e30805a2f7c2d1942a7f208966b2b8e2ebd86dfa0f2e10235c` | 1440x1200 | E03;E06;E07;E09 |
| CAP-07 | Incertidumbre H/E | `capturas/CAP-07_incertidumbre_he.png` | `3ba932645e176211ee5c46399b6000ab9bf1b3be0da7e937eeed802dab7358c5` | 1440x1200 | E03;E06;E09 |
| CAP-08 | Valores atípicos | `capturas/CAP-08_valores_atipicos.png` | `1cc6626a4a6e0a75d1261369a564d55c5981a612a747ff81c229524a7174f9aa` | 1440x1200 | E03;E06;E07 |
| CAP-09 | Algoritmo A | `capturas/CAP-09_algoritmo_a.png` | `bce4f17b165db4b013d5aea55e5d454278b26f23756bfa7745c1ea1fc4e37a0e` | 1440x1200 | E02;E03;E06;E09 |
| CAP-10 | Valor consenso | `capturas/CAP-10_valor_consenso.png` | `93e07d0b4eed59d0a09725995eca82e85b48b32037c9b1f5a705eb2d66d6430f` | 1440x1200 | E03;E06;E07;E09 |
| CAP-11 | Compatibilidad metrológica | `capturas/CAP-11_compatibilidad_metrologica.png` | `03ea6d8474190b82f781b5d73bfab1601c2ef51675a6569f28fe8caacc0833ba` | 1440x1200 | E03;E06;E07;E09 |
| CAP-12 | Resumen de puntajes | `capturas/CAP-12_puntajes_resumen.png` | `68094bd11f265998f934bb5c6b42fd46a8180b4d13aca688bc4694a3577d058b` | 1440x1200 | E04;E06;E07;E09 |
| CAP-13 | Puntajes z y z' | `capturas/CAP-13_puntajes_zprima.png` | `9d89f0292d0c0b3544bfb37bdd95e69766d8f9baa21ecbf1670619a0b806bd49` | 1440x1200 | E04;E06;E07 |
| CAP-13 | Puntajes z y z' | `capturas/CAP-13_puntajes_z.png` | `dd7423b607e2aa78e01230280200a5e054581bdcfacecba69377d067f63a4f98` | 1440x1200 | E04;E06;E07 |
| CAP-14 | Puntajes zeta y En | `capturas/CAP-14_puntajes_zeta.png` | `5700bcb597a84a4bba8584ca81ac0f857430fe2284d0c5ce274f146c54be5c3f` | 1440x1200 | E04;E06;E07 |
| CAP-14 | Puntajes zeta y En | `capturas/CAP-14_puntajes_en.png` | `07d15f46a1ea028e63d84f1893445e32b0bed02167ab74a25314a74e8857993f` | 1440x1200 | E04;E06;E07 |
| CAP-15 | Informe global | `capturas/CAP-15_informe_global.png` | `f591cd3b22ca383507598c5eb719a19666b98c8a5c8afdb200b8031ba46e289e` | 1440x1200 | E06;E07;E09 |
| CAP-16 | Participantes | `capturas/CAP-16_participantes.png` | `b481c06f11b2fe9dbb8904c6283ec95b14152fc7822a5d9f6f57b8120fb4755c` | 1440x1200 | E06;E07 |
| CAP-17 | Generación de informes | `capturas/CAP-17_generacion_informes.png` | `4bfd8a4b4f0fd7ecb865ec0d9e3ce38965b3c85f25a27c680c9415e6a1f0b968` | 1440x1200 | E06;E08;E09 |
| CAP-18 | Error de archivo | `capturas/CAP-18_error_archivo.png` | `6cf33a287460ebbe3fe62501bd775f5cb09229e47a90391e9e49900656f0b4e7` | 1440x1200 | E06;E08 |
| CAP-19 | Vista en resolución menor | `capturas/CAP-19_resolucion_menor.png` | `596c0e5f8bf3776f12ffb1ac6ef59e9b280cdcf8d48de2930441e0c5cd17dd54` | 1024x768 | E05;E06;E08 |

## Criterios de control

- Cada captura exige contenido semántico visible antes de guardarse.
- La ejecución falla ante errores de página o consola no reconocidos.
- El registro conserva incluso diagnósticos conocidos no bloqueantes.
- Los nombres, hashes, fecha, commit, resolución y datos quedan registrados.
- CAP-19 usa 1024×768; las demás capturas usan 1440×1200.

## Diagnósticos aceptados

El JSON conserva un 404 de favicon y el error `adjustWidth` que DT emite al redimensionar una tabla oculta. No alteran contenido ni cálculos; cualquier otro diagnóstico hace fallar la corrida. Su eliminación queda como riesgo técnico residual para una fase de mantenimiento.
