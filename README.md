

#  Resumen del Sistema
Una plataforma serverless que permite a los ciudadanos presentar reclamos, hacer seguimiento y recibir notificaciones, mientras que los funcionarios pueden gestionar, procesar y generar reportes.


#  FASE 1: ENTRADA Y AUTENTICACIÓN

#  Acceso del Usuario
1. *Ciudadano* abre navegador y accede al dominio público
2. *Route 53* resuelve el DNS y dirige al usuario
3. *CloudFront* (CDN) entrega la aplicación web estática desde caché global
4. *S3* sirve archivos estáticos (HTML, CSS, JS, imágenes) a CloudFront
5. *Cognito* maneja autenticación:
   - Login con usuario/contraseña
   - Registro de nuevos usuarios
   - Recuperación de contraseñas
   - *Genera JWT token* para sesiones seguras


##  *FASE 2: DISTRIBUCIÓN DE SOLICITUDES*

###  *API Gateway - El Portero Inteligente*
*API Gateway* recibe todas las peticiones del frontend y las distribuye según el tipo:

| *Tipo de Solicitud* | *Método HTTP* | *Endpoint* | *Destino* |
|----------------------|-----------------|--------------|-------------|
| Crear reclamo | POST /reclamos | /reclamos | *Lambda-Reclamos* |
| Consultar reclamo | GET /reclamos/{id} | /reclamos/{id} | *Lambda-Reclamos* |
| Actualizar reclamo | PUT /reclamos/{id} | /reclamos/{id} | *Lambda-Reclamos* |
| Listar reclamos | GET /reclamos | /reclamos | *Lambda-Reclamos* |
| Generar reportes | GET /reportes | /reportes | *Lambda-Reportes* |

###  *Validaciones en API Gateway:*
- Verifica JWT token de Cognito
- Valida formato de requests
- Aplica rate limiting
- Logs de auditoría


##  *FASE 3: PROCESAMIENTO PRINCIPAL*

###  Lambda-Reclamos

#### *Crear Reclamo Nuevo:*

1. Recibe solicitud POST con datos del reclamo
2. Valida datos obligatorios (ciudadano, tipo, descripción)
3. Genera ID único y timestamp
4. Guarda en DynamoDB tabla "Reclamos"
5. ENVÍA mensaje a SQS-Procesamiento para proceso asíncrono
6. Retorna respuesta inmediata al usuario (201 Created)


#### *Consultar/Actualizar Reclamos:*

1. Ejecuta operación CRUD en DynamoDB
2. Aplica filtros de seguridad (usuario solo ve sus reclamos)
3. Para actualizaciones: envía a SQS si requiere procesamiento adicional
4. Retorna datos al frontend


###  *Lambda-Reportes (Analytics & Reports)*

1. Consulta DynamoDB con filtros complejos
2. Procesa datos para generar:
   - Reportes por período
   - Estadísticas por categoría
   - Métricas de rendimiento
   - Dashboards para funcionarios
3. Retorna datos formateados (JSON, CSV)




##  *FASE 4: PROCESAMIENTO ASÍNCRONO*

###  *SQS-Procesamiento (Cola de Tareas)*
- *Propósito*: Desacoplar procesamiento pesado del flujo principal
- *Beneficios*: Usuario no espera, mejor performance
- *Contenido*: Mensajes con ID de reclamo y tipo de procesamiento

###  *Lambda-Procesamiento (Trabajo Pesado)*
*Se activa automáticamente cuando hay mensajes en SQS:*

#### *Tareas que Ejecuta:*

1.  CLASIFICACIÓN AUTOMÁTICA:
   - Analiza texto del reclamo
   - Asigna categoría (Servicios Públicos, Infraestructura, etc.)
   - Determina prioridad (Alta, Media, Baja)
   - Calcula tiempo estimado de resolución

2.  ENRIQUECIMIENTO DE DATOS:
   - Consulta APIs externas (si necesario)
   - Obtiene datos geográficos
   - Valida información del ciudadano
   - Accede a Secrets Manager para claves de APIs externas

3.  ACTUALIZACIÓN EN BASE DE DATOS:
   - Actualiza registro en DynamoDB con nueva información
   - Cambia estado: "PENDIENTE" → "EN_PROCESO"

4.  GENERACIÓN DE NOTIFICACIONES:
   - Si requiere notificación → Envía mensaje a SNS
   - Si reclamo es urgente → Notificación inmediata
   - Si es rutinario → Programar notificación


###  *Secrets Manager Integration:*
- Lambda-Procesamiento obtiene claves seguras para:
  - APIs de terceros
  - Credenciales de bases de datos externas
  - Tokens de servicios de geolocalización



##  *FASE 5: SISTEMA DE NOTIFICACIONES*

###  *SNS (Simple Notification Service)*
*Hub central de notificaciones* que recibe mensajes de:
- Lambda-Procesamiento (reclamos procesados)
- Lambda-ControlPlazos (reclamos atrasados)

#### *Tipos de Notificaciones:*
-  Confirmación: "Reclamo creado exitosamente"
-  Actualización: "Estado de reclamo cambió"
-  Alerta: "Reclamo próximo a vencer"
-  Urgente: "Reclamo vencido sin resolver"

###  *Lambda-Notificaciones (Dispatcher)*
*Se activa por eventos de SNS:*

1. Recibe mensaje de SNS con datos de notificación
2. Determina tipo de notificación y destinatarios
3. Formatea mensaje según canal:
   - Email para ciudadanos
   - SMS para casos urgentes
   - Push notifications para funcionarios
4. Envía a SES para entrega final


###  *SES (Simple Email Service)*
- Envía emails con plantillas profesionales
- Maneja bounces y complaints
- Tracking de entrega y apertura


##  *FASE 6: CONTROL AUTOMÁTICO DE PLAZOS*

###  *EventBridge/CloudWatch Events (Scheduler)*
- *Ejecuta cada día a las 08:00 AM*
- Trigger automático para Lambda-ControlPlazos

###  *Lambda-ControlPlazos (Automated Monitoring)*
*Ejecuta tareas de mantenimiento diarias:*

1.  CONSULTA RECLAMOS PENDIENTES:
   - Busca en DynamoDB reclamos en estado "EN_PROCESO"
   - Filtra por fechas de vencimiento

2.  IDENTIFICA SITUACIONES CRÍTICAS:
   - Reclamos próximos a vencer (2 días)
   - Reclamos ya vencidos
   - Reclamos sin actividad por >7 días

3.  ACTUALIZA ESTADOS:
   - Cambia estado a "ATRASADO" si corresponde
   - Actualiza contadores de días transcurridos
   - Marca prioridad como "URGENTE" si necesario

4.  GENERA ALERTAS:
   - Envía mensajes a SNS para notificaciones
   - Notifica a funcionarios responsables
   - Alerta a supervisores en casos críticos



##  *FASE 7: ORQUESTACIÓN COMPLEJA (OPCIONAL)*

###  *Step Functions (Workflow Orchestrator)*
Para *procesos complejos* que requieren múltiples pasos:

Ejemplo: Reclamo de Infraestructura Crítica
1. Lambda-Reclamos → Crear reclamo
2. Lambda-Procesamiento → Clasificar como crítico
3. API Externa → Consultar datos de infraestructura
4. Lambda-Validación → Verificar información
5. Lambda-Asignación → Asignar equipo especializado
6. Lambda-Notificaciones → Alertar múltiples stakeholders
