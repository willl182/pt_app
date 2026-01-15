# Guía de Implementación y Pruebas: Scripts de Validación E9

**Fecha:** 2026-01-03  
**Ubicación:** `entregas/E9_validacion/`

---

## 1. Scripts Disponibles

| Script | Módulo | Dependencias |
|--------|--------|--------------|
| `test_niqr.R` | nIQR | Base R |
| `test_made.R` | MADe | Base R |
| `test_algoritmo_a.R` | Algoritmo A | Base R |
| `test_puntajes.R` | Puntajes z, z', zeta, En | dplyr |
| `test_outliers.R` | Grubbs | outliers |

---

## 2. Ejecución Individual

### Desde VS Code Terminal:

```bash
cd /home/w182/w421/pt_app

# Ejecutar cada script individualmente
Rscript entregas/E9_validacion/test_niqr.R
Rscript entregas/E9_validacion/test_made.R
Rscript entregas/E9_validacion/test_algoritmo_a.R
Rscript entregas/E9_validacion/test_puntajes.R
Rscript entregas/E9_validacion/test_outliers.R
```

---

## 3. Ejecución Completa (Todos los Scripts)

### Script de ejecución masiva:

```bash
cd /home/w182/w421/pt_app/entregas/E9_validacion

for script in test_*.R; do
  echo "=== Ejecutando $script ==="
  Rscript "$script"
  echo ""
done
```

---

## 4. Interpretación de Resultados

### Salida Exitosa:
```
============================================
  RESUMEN DE VALIDACIÓN: [Módulo]
============================================
  Total de casos: X
  Casos exitosos: X
  Casos fallidos: 0
  Tasa de éxito: 100%

  ✓ MÓDULO VALIDADO
============================================
```

### Salida con Errores:
```
  [FALLA] Caso X: valor_calculado ≠ valor_esperado
  ...
  ✗ VALIDACIÓN FALLIDA
```

---

## 5. Solución de Problemas

| Error | Solución |
|-------|----------|
| `package 'dplyr' not found` | `install.packages("dplyr")` |
| `package 'outliers' not found` | `install.packages("outliers")` |
| Diferencias numéricas pequeñas | Verificar tolerancia (0.0001) |

---

## 6. Resumen de Casos de Prueba

| Script | Casos | Aspectos Validados |
|--------|-------|-------------------|
| test_niqr.R | 6 | Datos normales, atípicos, NA, vacíos |
| test_made.R | 7 | Robustez, comparación con SD |
| test_algoritmo_a.R | 6 | Convergencia, atípicos, límites |
| test_puntajes.R | 15+ | z, z', zeta, En, evaluaciones |
| test_outliers.R | 3 | Detección Grubbs |
