# Guía de Ejecución de Tests - PT App

Esta guía proporciona instrucciones detalladas para ejecutar las pruebas de validación de los entregables ubicados en el directorio `deliv/`. Estas pruebas aseguran la integridad del código, la precisión de los cálculos estadísticos según la norma ISO 13528:2022 y el correcto funcionamiento de la interfaz de usuario.

## Requisitos Previos

Para ejecutar las pruebas, es necesario contar con un entorno de R funcional y las dependencias correspondientes.

### Software Requerido
- **R versión 4.0 o superior**
- **Paquete `testthat`**: Framework principal para las pruebas.
- **Paquete `digest`**: Utilizado para la verificación de integridad mediante hashes SHA256.

### Instalación de Dependencias
Ejecute el siguiente comando en su consola de R para instalar los paquetes necesarios:

```r
install.packages(c("testthat", "digest"))
```

### Archivos de Datos Necesarios
Los tests dependen de la presencia de archivos de datos en el directorio `data/` de la raíz del proyecto:
- `data/homogeneity.csv`
- `data/stability.csv`
- `data/summary_n4.csv`

## Resumen de la Estructura de Tests

El proyecto cuenta con 11 archivos de prueba distribuidos en los diferentes entregables:

| Entregable | Archivo de Test | Alcance de la Validación |
| :--- | :--- | :--- |
| **01** | `test_01_existencia_archivos.R` | Verifica archivos críticos, estructura de `ptcalc`, sintaxis R y hashes SHA256. |
| **02** | `test_02_firma_funciones.R` | Valida que las firmas de las funciones coincidan con la documentación técnica. |
| **03** | `test_03_homogeneity.R` | Compara estadísticos de homogeneidad contra valores de referencia en CSV. |
| **03** | `test_03_stability.R` | Valida cálculos de estabilidad y diferencias medias (Homogeneidad vs Estabilidad). |
| **03** | `test_03_sigma_pt.R` | Verifica algoritmos de Sigma PT: nIQR, MADe y Algoritmo A. |
| **04** | `test_04_puntajes.R` | Valida el cálculo exacto de puntajes z, z', zeta y En. |
| **05** | `test_05_navegacion.R` | Prueba la lógica de navegación y estados de la interfaz de usuario. |
| **06** | `test_06_logica.R` | Valida la lógica interna de procesamiento y reactividad de la aplicación. |
| **07** | `test_07_graficos.R` | Asegura la correcta generación y estructura de los objetos gráficos. |
| **08** | `test_08_end_to_end.R` | Prueba el flujo completo: Carga → Homogeneidad → Estabilidad → Puntajes. |
| **09** | `test_09_reproducibilidad.R` | Garantiza que los mismos inputs produzcan siempre los mismos resultados. |

## Métodos de Ejecución

### 1. Ejecución de un Test Individual
Ideal para depurar un componente específico. Desde una sesión de R:

```r
library(testthat)
# Establecer el directorio de trabajo en la raíz del proyecto
setwd("/home/w182/w421/pt_app")

# Ejecutar el test de cálculos de puntajes (ejemplo)
test_file("deliv/04_puntajes/tests/test_04_puntajes.R")
```

### 2. Ejecución por Directorio de Entregable
Útil para validar un módulo completo durante el desarrollo:

```r
library(testthat)
# Ejecutar todos los tests de cálculos PT (Entregable 03)
test_dir("deliv/03_calculos_pt/tests")
```

### 3. Ejecución Global de Entregables (Recomendado)
Para una validación completa de todos los entregables antes de un commit o entrega final, utilice el script de verificación global desde la terminal:

```bash
# Desde la raíz del proyecto
Rscript deliv/scripts/verifica_entregables.R
```

Este script automatiza el recorrido por todas las subcarpetas de `deliv/`, ejecuta los tests encontrados y presenta un resumen de éxitos y fallos.

## Archivos de Validación Internos
Algunos directorios de tests contienen sus propios archivos `.csv` (como en `deliv/03_calculos_pt/tests/`). Estos archivos contienen los resultados esperados ("Golden Results") que se comparan bit a bit con los cálculos en tiempo real para detectar regresiones.

## Solución de Problemas

| Problema | Posible Causa | Solución |
| :--- | :--- | :--- |
| **"No se pudo abrir el archivo"** | Ruta incorrecta o directorio de trabajo mal configurado. | Ejecute `getwd()` en R para confirmar que está en `/home/w182/w421/pt_app`. |
| **"Could not find function"** | El paquete `ptcalc` o las funciones de `app.R` no están cargadas. | Asegúrese de que el entorno tenga acceso a las funciones necesarias antes de correr el test. |
| **"Hash no coincide"** | Se modificó un archivo fuente que está bajo control de integridad. | Verifique si el cambio fue intencional. Si es así, actualice el hash esperado en `test_01_existencia_archivos.R`. |
| **Fallo en tests de Homogeneidad** | Datos de entrada en `data/` han cambiado. | Verifique que `homogeneity.csv` sea el correcto para los casos de prueba. |

---
**Nota:** Para más detalles sobre casos de prueba específicos, consulte los archivos `guia_uso_tests.md` dentro de las carpetas de cada entregable.
