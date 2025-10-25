# **Plan General de Auditoría: Aplicativo Estadístico de EA**

Este documento sirve como hoja de ruta para la auditoría semanal del proyecto.

* \[ \] **Semana 1: Estructura y Carga de Datos**  
  * \[ \] ¿La estructura del código es lógica y mantenible?  
  * \[ \] ¿La carga de datos es funcional para todos los archivos requeridos?  
  * \[ \] ¿La validación de datos de entrada es lo suficientemente robusta para prevenir errores?  
* \[ \] **Semana 2: Módulo de Validación de Ítems**  
  * \[ \] ¿Los cálculos de homogeneidad (ANOVA) son correctos?  
  * \[ \] ¿Los cálculos de estabilidad (t-test) son correctos?  
  * \[ \] ¿Se aplica correctamente el criterio de aceptación (0.3·σpt)?  
* \[ \] **Semana 3: Núcleo de Análisis Robusto**  
  * \[ \] ¿La implementación del Algoritmo A es correcta y sigue la norma?  
  * \[ \] ¿El cálculo de MADe y nIQR es preciso?  
  * \[ \] ¿Los resultados coinciden con cálculos de validación externos?  
* \[ \] **Semana 4: Indicadores y Reportes**  
  * \[ \] ¿Los cálculos de los puntajes de desempeño (z, z', ζ, En) son correctos?  
  * \[ \] ¿El módulo de generación de informes es funcional?  
  * \[ \] ¿La plantilla de informe (contenido) está lista para ser desarrollada?  
* \[ \] **Semana 5: Interfaz de Usuario (UI/UX)**  
  * \[ \] ¿La navegación es intuitiva y sigue un flujo lógico?  
  * \[ \] ¿Todos los controles de entrada (inputs) son funcionales?  
  * \[ \] ¿La disposición de los elementos es clara y no está sobrecargada?  
* \[ \] **Semana 6: Integración UI-Servidor**  
  * \[ \] ¿Las acciones del usuario en la UI activan correctamente los análisis en el servidor?  
  * \[ \] ¿Los resultados se muestran de forma reactiva en la UI?  
  * \[ \] ¿La aplicación maneja estados (ej. carga, resultados listos) de forma clara?  
* \[ \] **Semana 7: Visualizaciones**  
  * \[ \] ¿Todos los gráficos requeridos (boxplots, histogramas, etc.) están presentes?  
  * \[ \] ¿Las visualizaciones representan correctamente los datos?  
  * \[ \] ¿Los ejes, títulos y leyendas son claros y descriptivos?  
* \[ \] **Semana 8: Finalización y Documentación**  
  * \[ \] ¿El código está suficientemente comentado?  
  * \[ \] ¿Se ha iniciado la redacción del manual de usuario?  
  * \[ \] ¿Existen pruebas (aunque sean informales) que cubran los flujos principales?  
* \[ \] **Semana 9: Validación Formal**  
  * \[ \] ¿Se ha definido el plan para el informe de validación?  
  * \[ \] ¿Se han preparado los casos de prueba para la validación formal?