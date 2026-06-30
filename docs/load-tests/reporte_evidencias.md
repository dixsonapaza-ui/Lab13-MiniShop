# Reporte de Evidencias: Pruebas de Carga con Apache JMeter
**Curso:** Construcción y Pruebas de Software  
**Laboratorio:** N° 15 — Pruebas de Carga con Apache JMeter  
**Ciclo:** IV  
**Modalidad:** Individual / parejas  

---

## 1. Tabla de Métricas Completada (Dashboard - Statistics)

Las siguientes métricas fueron extraídas directamente del reporte HTML (`statistics.json`) generado después de la ejecución en modo no-GUI de Apache JMeter 5.6.3:

| Métrica / Endpoint | Valor Obtenido | Criterio de Aceptación | ¿Cumple? | Detalle / Observación |
| :--- | :--- | :--- | :---: | :--- |
| **p90** `GET /api/products` | **5.0 ms** | $\le$ 500 ms | **SÍ** | Respuesta sumamente rápida debido a la ejecución en memoria (H2). |
| **p95** `GET /api/products` | **6.0 ms** | $\le$ 800 ms | **SÍ** | Excelente margen respecto al límite establecido. |
| **Error %** `GET /api/products` | **0.00%** | $\le$ 1% | **SÍ** | Ninguna petición falló durante el escenario. |
| **Throughput Total** | **18.62 req/s** | $\ge$ 30 req/s | **NO** | *Ver explicación técnica abajo.* |

### Explicación del Throughput de 18.62 req/s:
El throughput obtenido fue de **18.62 req/s**, lo cual no alcanza el criterio mínimo de 30 req/s. Sin embargo, esto **no se debe a una degradación o saturación de la aplicación MiniShop**, sino al **diseño y configuración del Plan de Prueba**:
1. El **TG-01** (100 hilos, 30s ramp-up, loop 3) e inyecta un total de 300 peticiones en 30 segundos ($\approx 10$ req/s).
2. El **TG-02** (50 hilos, 20s ramp-up, loop 5) e inyecta un total de 250 peticiones en 20 segundos ($\approx 12.5$ req/s).
3. Dado que las peticiones se completan extremadamente rápido ($\approx 3.5$ ms por petición), cada hilo inicia, ejecuta sus ciclos en menos de 15 ms y termina de inmediato.
4. Por lo tanto, las peticiones se inyectan de forma espaciada conforme arranca cada hilo en el periodo de Ramp-up. La tasa global de inyección promedio impuesta por la prueba fue de 18.62 req/s.
5. **Para cumplir con $\ge$ 30 req/s:** Sería necesario configurar los Thread Groups con **Loop Count infinito** y establecer un tiempo de duración fijo (ej. 60 segundos) o reducir el tiempo de Ramp-up para inyectar más carga en menos tiempo.

---

## 2. Análisis Redactado por Endpoint

### Endpoint: `GET /api/products`
> El endpoint `GET /api/products` procesó 300 peticiones con un throughput de 10.16 req/s. El p95 fue de 6.0 ms, lo cual cumple con el criterio de aceptación de 800ms. Se observó un comportamiento óptimo y altamente estable con 0.00% de errores, beneficiándose del almacenamiento de datos en la base de datos H2 en memoria. El posible cuello de botella identificado es la inyección artificial de hilos y el bajo número de ciclos configurados en JMeter, que limitó el volumen total de peticiones por segundo. La acción recomendada es aumentar la cantidad de ciclos a infinito y establecer un tiempo límite de duración (ej. 1 minuto) para inyectar carga constante y medir el throughput máximo real del servidor.

### Endpoint: `GET /api/products/1`
> El endpoint `GET /api/products/1` procesó 250 peticiones con un throughput de 12.83 req/s. El p95 fue de 5.0 ms, lo cual cumple con el criterio de aceptación de 800ms. Se observó una latencia aún menor que la del listado general, ya que la consulta de una entidad por su clave primaria (ID) sobre una tabla en memoria es una operación directa de orden de complejidad $O(1)$. El posible cuello de botella identificado es el mismo límite impuesto por el ritmo de inyección de hilos de JMeter. La acción recomendada es ejecutar una segunda ronda con un Ramp-up de 5 segundos para evaluar cómo reacciona el pool ante una inyección agresiva y repentina de usuarios.

---

## 3. Identificación y Justificación del Cuello de Botella

Bajo las condiciones actuales de la prueba, **no existe un cuello de botella físico** en el servidor de MiniShop. El servidor respondió al 100% de las solicitudes en menos de 60 ms en el peor caso (Max Response Time total = 59 ms), con promedios generales de **3.45 ms** y sin errores.

Sin embargo, si la prueba se escalara a un entorno de producción o con mayor carga sostenida, los cuellos de botella más probables son:

1. **Tamaño del Pool de Conexiones de HikariCP:**
   * **Justificación:** Spring Boot configura por defecto un pool máximo de 10 conexiones simultáneas a la base de datos. Si aumentamos la concurrencia real sostenida a cientos de usuarios consultando activamente, los hilos de Tomcat empezarán a bloquearse esperando que se libere una conexión del pool, aumentando drásticamente los tiempos de respuesta (latencia de encolamiento).
2. **Concurrencia en la Base de Datos H2:**
   * **Justificación:** Al ser una base de datos en memoria y monoproceso, aunque sea extremadamente veloz, no está diseñada para manejar grandes cargas de transacciones concurrentes en producción, sirviendo principalmente para entornos de desarrollo y pruebas unitarias/integración.

---

## 4. Preguntas de Reflexión

### 1. ¿Por qué se recomienda usar el modo -n (no-GUI) de JMeter para pruebas reales en lugar de la interfaz gráfica?
**Respuesta:** El modo gráfico (GUI) consume recursos sustanciales de CPU y memoria RAM para renderizar paneles, árboles de resultados y gráficos dinámicos. Si se usa la GUI para pruebas con cargas altas, la máquina que genera las pruebas puede quedarse sin recursos antes de que el servidor bajo prueba se sature. Esto introduce latencia artificial en las mediciones, arrojando falsos cuellos de botella. El modo no-GUI (`-n`) es muy liviano, consume mínimos recursos y garantiza la exactitud de los tiempos registrados.

### 2. El p95 de GET /api/productos fue de X ms (en nuestro caso, 6.0 ms). ¿Qué porcentaje de tus usuarios experimentaría un tiempo de respuesta mayor a ese valor?
**Respuesta:** El percentil 95 (p95) define que el 95% de las solicitudes tardaron 6.0 ms o menos en responder. Por lo tanto, exactamente el **5%** de los usuarios experimentará tiempos de respuesta superiores a 6.0 ms.

### 3. Si aumentaras el número de usuarios concurrentes de 100 a 500, ¿qué componente del sistema crees que fallaría primero? ¿Por qué?
**Respuesta:** Fallaría primero el **pool de conexiones de HikariCP** en la aplicación Spring Boot. Al tener un límite predeterminado de 10 conexiones activas, con 500 usuarios concurrentes haciendo peticiones al mismo tiempo, el encolamiento de hilos Tomcat esperando conexión superaría rápidamente el tiempo de espera máximo permitido (`connectionTimeout` por defecto de 30,000ms), provocando excepciones del tipo `SQLTransientConnectionException` (tasa de error alta) y aumentando la latencia general a más de 30 segundos para las peticiones en cola.

### 4. ¿Cómo se relaciona el tamaño del pool de conexiones de HikariCP con el throughput máximo que puede alcanzar tu aplicación?
**Respuesta:** El pool de conexiones limita el paralelismo físico con la base de datos. Si el pool tiene un tamaño máximo de $N$ conexiones y cada consulta a la base de datos toma un promedio de $T$ segundos, el throughput máximo teórico que la base de datos puede procesar es:
$$\text{Throughput Máximo} = \frac{N}{T} \text{ req/s}$$
Si queremos incrementar el throughput máximo bajo alta concurrencia, debemos aumentar el tamaño del pool ($N$) —siempre que la base de datos y la CPU lo soporten— o reducir el tiempo de consulta ($T$) optimizando consultas con índices, caché de segundo nivel o simplificación de queries.

---

## 5. Estructura de Archivos del Laboratorio 15

Todos los entregables solicitados han sido generados y organizados dentro del repositorio local en `docs/load-tests/`:

* **`minishop-load-test.jmx`:** Archivo XML con el plan de pruebas diseñado (endpoints ajustados a `/api/products` del proyecto real).
* **`resultados.jtl`:** Resultados de pruebas en formato bruto.
* **`reporte-html/`:** Carpeta con el reporte web interactivo.
* **`reporte-html.zip`:** Archivo comprimido listo para su envío o subida a Drive.
* **`reporte_evidencias.md`:** Este documento detallado con el análisis y reflexiones del laboratorio.
