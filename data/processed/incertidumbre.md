# Incertidumbre Tipo A — Promedio Horario CALAIRE

## Alcance

Este documento describe la incertidumbre estándar Tipo A asociada a cada promedio
horario calculado en el pipeline de preprocesamiento CALAIRE.

## Unidad estadística

Cada promedio horario se calcula a partir de exactamente **n = 60** lecturas
minutales válidas que cubren los minutos 00 a 59 de una hora calendario.

## Fórmulas

```
media_h  =  (1/n) * sum(x_i)           n = 60

sd_h     =  sqrt( sum((x_i - media_h)^2) / (n - 1) )

u_h      =  sd_h / sqrt(n)  =  sd_h / sqrt(60)
```

## Criterios de inclusión

- La hora calendario debe contener exactamente 60 registros minutales únicos.
- Los minutos deben ser 00 a 59 sin ausencias.
- Todas las lecturas del instrumento deben ser numéricas y no-NA.
- El bloque debe estar definido en `diseno_estabilidad_homogeneidad.csv`.

## Criterios de exclusión

- Horas parciales al inicio o final de un bloque (menos de 60 minutos).
- Horas con uno o más valores NA en la columna del instrumento.
- Bloques fuera del rango definido en la tabla de diseño.

## Advertencia

`u_h` cubre únicamente la **repetibilidad minutal** del instrumento dentro de
una hora. **No** representa la incertidumbre metrológica total.

### Componentes NO incluidos

- Incertidumbre del patrón de referencia
- Incertidumbre de calibración
- Deriva a largo plazo
- Resolución del instrumento
- No-linealidad
- Concentración residual / blanco
- Variación por condiciones ambientales (T, P, HR)

Para incertidumbre expandida: `U = k * u_h` con k = 2 (aprox. 95 %).

## Resumen de horas válidas procesadas

- Total horas evaluadas: 46
- Horas válidas: 22
- Horas inválidas (parciales/NA): 24

