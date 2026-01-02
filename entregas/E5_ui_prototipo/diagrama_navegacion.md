# Entregable 5.2: Diagrama de Navegación de la UI

El siguiente diagrama representa el flujo de interacción del usuario dentro del aplicativo, desde la entrada de datos hasta la obtención del producto final (informe).

```mermaid
graph TD
    Start((Inicio)) --> Load[Carga de Datos]
    
    subgraph "Módulos de Preparación"
        Load --> Hom[Evaluación de Homogeneidad]
        Hom --> Stab[Evaluación de Estabilidad]
    end
    
    subgraph "Módulos de Evaluación"
        Stab --> VA[Valor Asignado y Sigma_pt]
        VA --> Scores[Cálculo de Puntajes PT]
    end
    
    subgraph "Salida"
        Scores --> Report[Generación de Informes]
        Report --> Word([Descargar Word])
    end
    
    style Start fill:#f9f,stroke:#333,stroke-width:2px
    style Word fill:#007bff,color:#fff,stroke-width:2px
```

## Descripción del Flujo

1. **Carga de Datos:** El usuario debe subir obligatoriamente los archivos `homogeneity.csv`, `stability.csv` y los resúmenes de participantes.
2. **Preparación:** Se verifica que el ítem sea apto (homogéneo y estable). Sin esta verificación, los resultados posteriores carecen de base técnica.
3. **Cálculo:** Se selecciona el método de consenso o referencia para establecer el valor central y su dispersión.
4. **Evaluación:** Se generan los puntajes individuales (z, En, etc.).
5. **Cierre:** Se exporta el informe oficial con todos los anexos técnicos incluidos.
