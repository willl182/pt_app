# Guía de Implementación y Pruebas: `verificar_dependencias.R`

Esta guía describe cómo implementar, ejecutar y validar el script de verificación de dependencias para asegurar que el entorno de R esté correctamente configurado para el aplicativo PT.

## 1. Prerrequisitos

Antes de ejecutar el script, asegúrese de tener instalado:
- **R** (Versión 4.0.0 o superior).
- Conexión a internet (necesaria para descargar paquetes si faltan).

---

## 2. Implementación del Script

El script `verificar_dependencias.R` se encuentra en la ruta:
`entregas/E1_repositorio/verificar_dependencias.R`

### Lógica del Script
1. Define un vector con los nombres de todos los paquetes requeridos.
2. Compara esta lista con los paquetes instalados en el sistema (`installed.packages()`).
3. Muestra un resumen del estado actual.
4. Proporciona instrucciones claras para la instalación de los componentes faltantes.

---

## 3. Cómo Ejecutar el Script

Existen tres métodos principales para ejecutar la verificación:

### Método A: Desde Visual Studio Code (Recomendado)
1. Instale la extensión **R** de Yuki Ueda en VS Code.
2. Abra el archivo `verificar_dependencias.R`.
3. Presione `Ctrl+Enter` para enviar el código a la terminal de R o haga clic en el icono de **Run** (flecha) en la esquina superior derecha si tiene configurado el terminal de R.
4. Alternativamente, use la paleta de comandos (`Ctrl+Shift+P`) y busque `R: Run Source`.

### Método B: Desde la Terminal Integrada de VS Code
Abra una terminal integrada en VS Code (`Ctrl+ñ` o `Ctrl+```) y ejecute:
```bash
Rscript entregas/E1_repositorio/verificar_dependencias.R
```

### Método C: Usando un Terminal Externo
Si no desea usar VS Code para la ejecución, navegue a la carpeta del proyecto y ejecute:
```bash
Rscript entregas/E1_repositorio/verificar_dependencias.R
```

---

## 4. Interpretación de Resultados

Al finalizar la ejecución, el script mostrará uno de los siguientes resultados en la consola:

### Caso 1: Entorno Listo
Si todas las librerías están presentes, verá un mensaje de confirmación con un check mark (✓):
> `✓ Todas las dependencias están correctamente instaladas.`
> `✓ Versión de R compatible.`

### Caso 2: Faltan Librerías
Si faltan paquetes, el script los listará y proporcionará el comando exacto para instalarlos:
> `Los siguientes paquetes NO están instalados:`
> `  - vroom`
> `  - plotly`
> `¿Desea instalar los paquetes faltantes? (Ejecute el siguiente código):`
> `install.packages(c("vroom", "plotly"))`

---

## 5. Pruebas de Validación

Para verificar que el script funciona correctamente, puede realizar la siguiente prueba de estrés:

1. **Desinstalar temporalmente un paquete no crítico** (ejemplo: `bsplus`):
   ```r
   remove.packages("bsplus")
   ```
2. **Ejecutar el script** de verificación:
   ```r
   source("entregas/E1_repositorio/verificar_dependencias.R")
   ```
3. **Validar:** El script debe identificar que `bsplus` falta y sugerir su instalación.
4. **Reinstalar:**
   ```r
   install.packages("bsplus")
   ```
5. **Ejecutar de nuevo:** El script debería reportar ahora que todo está correcto.

---

## 6. Mantenimiento

Si se añaden nuevas funcionalidades al aplicativo que requieran librerías adicionales:
1. Abra `verificar_dependencias.R`.
2. Añada el nombre del nuevo paquete al vector `required_packages`.
3. Guarde los cambios.
