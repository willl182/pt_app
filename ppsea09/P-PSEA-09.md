# P-PSEA-09 Procedimiento de Planificacion de Ronda de Ensayo de Aptitud

## 1. Informacion general del procedimiento

### 1.1 Objetivo

Establecer las directrices, responsabilidades y actividades necesarias para planificar cada ronda de ensayo de aptitud (EA) del Laboratorio CALAIRE, garantizando coherencia con ISO/IEC 17043:2023, ISO 13528:2022 y con el sistema de gestion de calidad institucional.

### 1.2 Alcance

Este procedimiento aplica a la planificacion previa al inicio de cada ronda de EA para gases contaminantes criterio, incluyendo definicion de objetivos, criterios de participacion, esquema logistico, control tecnico, analisis de riesgos, trazabilidad, comunicacion e integracion con el procedimiento estadistico `p-psea-06.md`.

### 1.3 Definiciones minimas

- `EA`: ensayo de aptitud.
- `item de ensayo`: material, mezcla, atmosfera o sistema de referencia utilizado para evaluar a los participantes.
- `participante`: laboratorio o entidad que ejecuta la medicion y reporta resultados.
- `ronda`: ciclo planificado de preparacion, medicion, evaluacion y reporte de un EA.

### 1.4 Documentos de referencia

- ISO/IEC 17043:2023.
- ISO 13528:2022.
- ILAC P9:01/2024.
- EA-4/18 G:2021.
- EA-4/21 INF:2018.
- ISO 17034.
- ISO 6143:2025, ISO 6142-1 y otras normas de mezclas gaseosas aplicables.
- Normas EN aplicables al metodo de medicion: EN 14211, EN 14212, EN 14625 y EN 14626.
- `p-psea-06.md`, procedimiento de diseno estadistico.
- Procedimientos del SGC para competencia, autorizaciones, compras, control documental, registros, riesgos, trabajo no conforme, quejas y apelaciones.

### 1.5 Condiciones generales

La transicion institucional a ISO/IEC 17043:2023 debe estar implementada antes del 31 de mayo de 2026. La planificacion de cada ronda debe asegurar imparcialidad, confidencialidad, control de riesgos y validez tecnica, remitiendo al SGC cuando el requisito ya este cubierto por procedimientos corporativos.

El Laboratorio CALAIRE opera principalmente rondas de modalidad central, en las que los participantes comparan sus mediciones frente a un sistema de referencia controlado por el organizador. Segun la ronda, podran existir elementos de modalidad in situ o de cilindros, pero el plan debe dejar explicita la modalidad adoptada y sus riesgos.

## 2. Informacion especifica del procedimiento

La planificacion de cada ronda se documenta antes de su inicio y debe cubrir, como minimo, los elementos aplicables de ISO/IEC 17043:2023, 7.2.1.3.

### 2.1 Requisitos transversales previos a los literales del plan

Antes de desarrollar el plan especifico de la ronda se debe verificar:

- imparcialidad del personal y ausencia de conflictos de interes, conforme al SGC;
- confidencialidad de la informacion de participantes, codificacion y control de acceso a datos;
- riesgos y oportunidades asociados a cambios significativos en el esquema, conforme al sistema institucional de gestion de riesgos;
- disponibilidad de recursos, instalaciones, equipos y software validado;
- autorizacion del personal para las funciones criticas definidas en ISO/IEC 17043:2023, 6.2.6.

### 2.2 Contenido minimo del plan de ronda

#### a) Personal involucrado

La ronda debe identificar las funciones autorizadas necesarias para:

- planificacion del esquema;
- evaluacion de datos para estabilidad, homogeneidad, valor asignado e incertidumbre;
- evaluacion del desempeno de participantes;
- emision de opiniones e interpretaciones tecnicas;
- revision y autorizacion del informe.

Los cargos institucionales podran variar, pero cada funcion debe estar asignada a personal competente y autorizado conforme al SGC.

#### b) Actividades de proveedores externos

Si la ronda utiliza proveedores externos para insumos, calibraciones, transporte, materiales de referencia u otros servicios de apoyo, estos deben estar evaluados y aprobados conforme al procedimiento institucional de compras y control de proveedores.

No podran subcontratarse el diseno y planificacion del esquema, la evaluacion del desempeno ni la autorizacion del informe final. Toda actividad externa permitida debe conservar trazabilidad, acuerdo de confidencialidad y evidencia de competencia.

#### c) Criterios de participacion

La convocatoria formal debe indicar como minimo que el participante debe:

- emplear metodos de medicion aceptados para el esquema;
- disponer de personal competente;
- usar equipos calibrados o verificados con trazabilidad demostrable;
- reportar resultados en el formato, unidad y plazo establecidos;
- reportar incertidumbre cuando el esquema la requiera;
- aceptar las condiciones de confidencialidad, integridad y no colusion.

#### d) Numero y tipo de participantes

El plan debe declarar la capacidad maxima de atencion simultanea y el numero esperado de participantes por analito o nivel.

Adicionalmente se adoptan las siguientes reglas:

- si `p >= 12`, puede emplearse consenso robusto conforme a `p-psea-06.md`;
- si `5 <= p < 12`, la ronda debe prever metodos robustos simplificados o valores externos segun aplique;
- si `p < 5`, la ronda debe planificarse como pequena comparacion interlaboratorio y preferir valor asignado externo y `sigma_pt` externa;
- cuando el numero esperado no sustente el diseno original, el plan debe documentar el enfoque alternativo y comunicarlo a los participantes.

#### e) Actividades y resultados esperados

El plan debe describir las actividades de la ronda y los resultados que reportaran los participantes, incluyendo:

- instalacion o alistamiento;
- condiciones de medicion;
- numero de mediciones o replicados requeridos;
- formato de reporte;
- variables adicionales requeridas, por ejemplo incertidumbre, metodo y observaciones;
- resultado tecnico esperado de la ronda.

#### f) Rango esperado de valores

El plan debe establecer los rangos de concentracion o niveles previstos para cada analito.

Para gases contaminantes criterio, los rangos se definen por ronda y pueden variar segun objetivo tecnico, estabilidad y capacidad del sistema. Como criterio general:

- CO y NO suelen admitir mezclas mas estables;
- NO2 puede presentar degradacion o dependencia del modo de generacion;
- SO2 en aire requiere especial control por su inestabilidad;
- O3 requiere generacion in situ.

Los niveles finales deben quedar documentados en el plan especifico y sustentados con evidencia tecnica.

#### g) Fuentes potenciales de error significativas

La ronda debe identificar las principales fuentes de error y vincularlas al sistema institucional de riesgos. Entre otras, deben considerarse:

- inestabilidad o falta de homogeneidad del item;
- fugas, presion, temperatura, humedad o contaminacion cruzada;
- errores del analizador segun tecnologia;
- errores de transcripcion, unidades o configuracion del equipo;
- colusion o falsificacion de resultados;
- retrasos logisticos o fallas de transporte.

Para gases contaminantes criterio, deben considerarse ademas riesgos especificos de:

- quimioluminiscencia para NOx;
- fluorescencia UV para SO2;
- NDIR para CO;
- fotometria UV para O3.

#### h) Requisitos tecnicos y de control

Los items y sistemas de referencia deben cumplir, segun aplique, con:

- trazabilidad metrologica;
- materiales de referencia o mezclas certificadas vigentes;
- equipos de referencia calibrados o verificados;
- control ambiental y operacional;
- evidencia de mantenimiento y aptitud de uso;
- estudios de homogeneidad y estabilidad;
- software validado para el tratamiento de datos.

Cuando la ronda corresponda a metodos de referencia para calidad del aire, deben considerarse como marco tecnico las normas EN 14211, EN 14212, EN 14625 y EN 14626, o el conjunto normativo definido expresamente para la ronda.

#### i) Medidas para prevenir colusion o falsificacion

La ronda debe incluir, segun aplique:

- codificacion unica de participantes;
- restriccion de visibilidad o intercambio de resultados durante la medicion;
- instrucciones expresas de no compartir datos;
- control de acceso a la informacion;
- evaluacion tecnica de patrones atipicos de coincidencia.

Los eventos sospechosos deben gestionarse conforme al procedimiento institucional aplicable.

#### j) Informacion a suministrar y cronograma

Antes del inicio de la ronda, el organizador debe suministrar:

- objetivo y alcance del EA;
- instrucciones tecnicas;
- cronograma con fechas de envio, medicion, reporte y cierre;
- condiciones de transporte, recepcion y manipulacion;
- formato de reporte;
- criterios de aceptacion de resultados y reglas para envios tardios.

#### k) Frecuencia y plazos de reporte

La frecuencia de las rondas y el plazo de reporte se establecen en el plan anual y en el cronograma de cada ronda. El plazo debe ser suficiente para obtener datos validos sin comprometer estabilidad del esquema ni oportunidad del analisis.

#### l) Metodos y procedimientos aplicables

El plan debe indicar los metodos permitidos o el marco tecnico aceptado para los participantes. Tambien debe indicar si la ronda admite diferentes metodos, diferentes tecnologias o un unico metodo de referencia.

#### m) Pruebas de homogeneidad y estabilidad

Antes de la evaluacion del desempeno se debe ejecutar el estudio de homogeneidad y estabilidad conforme a `p-psea-06.md`.

Como criterio general:

- la homogeneidad se considera suficiente si `s_s <= 0.3 sigma_pt`;
- la estabilidad se considera suficiente si `|Delta| <= 0.3 sigma_pt`.

Los resultados y datos fuente del estudio deben quedar archivados como parte del expediente tecnico de la ronda.

#### n) Formatos e informes de resultados del participante

La ronda debe definir el formato controlado de reporte y los campos obligatorios. Como minimo deben incluir:

- codigo del participante;
- analito y nivel;
- resultado;
- unidad;
- numero de cifras significativas;
- metodo o tecnologia aplicada;
- incertidumbre, cuando aplique;
- observaciones relevantes.

#### o) Analisis estadistico

El analisis estadistico de la ronda se ejecuta conforme a `p-psea-06.md`.

El plan debe definir, como minimo:

- metodo para establecer `x_pt`;
- origen de `sigma_pt`;
- criterio para usar `z`, `z'`, `zeta` o `E_n`;
- tratamiento previsto para grupos pequenos;
- software validado utilizado.

Como regla general:

- si `u(x_pt) < 0.3 sigma_pt`, usar `z`;
- si `u(x_pt) >= 0.3 sigma_pt`, usar `z'`;
- si hay incertidumbres reportadas y el objetivo es compatibilidad metrologica, usar `zeta` o `E_n`.

#### p) Trazabilidad e incertidumbre del valor asignado

El plan debe indicar la fuente del valor asignado y su cadena de trazabilidad. La incertidumbre definitiva debe integrar, segun aplique:

`u(x_pt,def) = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)`

La determinacion detallada de estas componentes se rige por `p-psea-06.md`.

#### q) Tratamiento de diferentes metodos o subgrupos

Cuando participen laboratorios con diferentes metodos, tecnologias o configuraciones, el plan debe definir si:

- se evaluan conjuntamente;
- se forman subgrupos tecnicos;
- se limita la participacion a un metodo especifico.

La decision debe justificarse para evitar comparaciones no equivalentes.

#### r) Criterios de desempeno

El plan debe indicar los criterios de interpretacion aplicables:

- `|z|`, `|z'|` o `|zeta| <= 2`: satisfactorio;
- `2 < |score| < 3`: cuestionable;
- `|score| >= 3`: no satisfactorio;
- `|E_n| <= 1`: satisfactorio;
- `|E_n| > 1`: no satisfactorio.

#### s) Informes y comunicacion de resultados

El informe de ronda debe contener, como minimo, los elementos obligatorios aplicables de ISO/IEC 17043:2023, 7.4.3.2, incluyendo:

- identificacion del esquema y de la ronda;
- fecha de emision;
- identificacion del organizador;
- identificacion unica de los participantes por codigo;
- descripcion del item y del mensurando;
- resultados reportados;
- valor asignado y su incertidumbre;
- `sigma_pt` o criterio equivalente;
- estadisticos de desempeno aplicados;
- interpretacion de resultados;
- declaracion sobre homogeneidad y estabilidad;
- observaciones sobre metodos o subgrupos;
- desviaciones del plan originalmente previsto;
- limitaciones relevantes;
- conclusion general de la ronda;
- responsable de revision tecnica;
- responsable de aprobacion;
- referencias a documentos o anexos aplicables;
- fecha o periodo de la ronda;
- aclaracion sobre confidencialidad;
- tratamiento de resultados tardios o excluidos.

#### t) Publicacion, confidencialidad y retencion

La identidad de los participantes debe mantenerse confidencial y gestionarse conforme a la politica institucional y a los procedimientos de control documental y registros.

Los informes publicos o compartidos externamente solo podran contener resultados agregados o codificados, salvo obligacion legal o acuerdo documentado diferente.

#### u) Contingencias

El plan debe definir acciones ante:

- perdida, dano o inestabilidad del item;
- indisponibilidad del sistema de referencia;
- numero insuficiente de participantes;
- fallas del software o de la captura de datos;
- retrasos logisticos;
- hallazgos que comprometan la validez tecnica de la ronda.

### 2.3 Tratamiento de trabajo no conforme

Cualquier evento que comprometa la validez de la ronda debe gestionarse como trabajo no conforme conforme al procedimiento institucional. Esto incluye:

- deteccion y evaluacion del evento;
- analisis de impacto sobre resultados y participantes;
- decision sobre continuidad, repeticion o anulacion parcial o total;
- notificacion a las partes interesadas cuando aplique;
- registro de la decision y de las acciones tomadas.

## 3. Registros

Como minimo deben conservarse:

- plan documentado de la ronda;
- lista de participantes y codigos;
- evaluacion de riesgos;
- evidencia de competencia y autorizacion del personal involucrado;
- comunicaciones enviadas;
- estudios de homogeneidad y estabilidad;
- base de datos de resultados;
- analisis estadistico y archivo de calculo;
- informe final emitido;
- registros de trabajo no conforme, quejas o apelaciones, si existieron.

## 4. Referencia cruzada con el procedimiento estadistico

La planificacion de la ronda debe remitir a `p-psea-06.md` para:

- seleccion del valor asignado;
- definicion de `sigma_pt`;
- estimacion de incertidumbre;
- estudios de homogeneidad y estabilidad;
- seleccion e interpretacion de puntajes de desempeno.

## 5. Control de cambios y aprobacion

Este procedimiento debe revisarse cuando cambien las normas de referencia, el modelo operativo de las rondas o la interfaz con el SGC institucional.

| Reviso | Aprobo |
| --- | --- |
|  |  |
