# Paquete ptcalc: Visión General

## Descripción
`ptcalc` es un paquete R que encapsula todas las **funciones matemáticas puras** para el cálculo de ensayos de aptitud según la norma **ISO 13528:2022**. No tiene dependencias de Shiny, lo que permite su uso independiente y facilita las pruebas unitarias.

## Ubicación
```
pt_app/
└── ptcalc/
    ├── DESCRIPTION        # Metadatos del paquete
    ├── NAMESPACE          # Funciones exportadas
    ├── LICENSE            # MIT License
    ├── README.md          # Documentación breve
    ├── R/
    │   ├── ptcalc-package.R     # Documentación del paquete
    │   ├── pt_robust_stats.R    # nIQR, MADe, Algoritmo A
    │   ├── pt_homogeneity.R     # Homogeneidad y estabilidad
    │   └── pt_scores.R          # z, z', ζ, En scores
    └── man/                     # Documentación roxygen2
```

## Uso en la Aplicación
```r
# Al inicio de cloned_app.R
devtools::load_all("ptcalc")
```

## Filosofía de Diseño
| Principio | Implementación |
|-----------|----------------|
| Separación de responsabilidades | Lógica matemática separada de UI |
| Funciones puras | Sin efectos secundarios |
| Documentación | roxygen2 con ejemplos |
| Testabilidad | Funciones independientes |

## Funciones Exportadas

### pt_robust_stats.R
- `calculate_niqr()` - Rango intercuartil normalizado
- `calculate_mad_e()` - MAD escalado
- `run_algorithm_a()` - Algoritmo A de ISO 13528

### pt_homogeneity.R
- `calculate_homogeneity_stats()` - Estadísticos de homogeneidad
- `calculate_homogeneity_criterion()` - Criterio 0.3σ
- `evaluate_homogeneity()` - Evaluación del criterio
- `calculate_stability_stats()` - Estadísticos de estabilidad
- `evaluate_stability()` - Evaluación de estabilidad
- `calculate_u_hom()`, `calculate_u_stab()` - Incertidumbres

### pt_scores.R
- `calculate_z_score()`, `calculate_z_prime_score()`
- `calculate_zeta_score()`, `calculate_en_score()`
- `evaluate_z_score()`, `evaluate_en_score()`
- `classify_with_en()` - Clasificación a1-a7

## Referencias
- ISO 13528:2022
- ISO 17043:2024
