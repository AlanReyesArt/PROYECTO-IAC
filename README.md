![Imagen de WhatsApp 2025-06-26 a las 10 57 29_a7faed47](https://github.com/user-attachments/assets/9acdc546-f230-4fe8-9e8b-58d45d604174)



#  Resumen del Sistema
Una plataforma serverless que permite a los ciudadanos presentar reclamos, hacer seguimiento y recibir notificaciones, mientras que los funcionarios pueden gestionar, procesar y generar reportes.


#  FASE 1: ENTRADA Y AUTENTICACIÓN

#  Acceso del Usuario
- Navegador del Usuario: El ciudadano o funcionario accede a la aplicación web.
- CloudFront (CDN): Entrega la aplicación web estática (frontend) desde su caché global para un acceso rápido y de baja latencia.
- S3 (Simple Storage Service): Sirve como el origen de los archivos estáticos (HTML, CSS, JS, imágenes) para CloudFront.
- WAF (Web Application Firewall): Protege el API Gateway de ataques web comunes, actuando como un escudo de seguridad.
- Cognito: Maneja la autenticación de usuarios (registro, inicio de sesión) y genera un JWT token para autorizar las solicitudes a la API de forma segura.


##  *FASE 2: DISTRIBUCIÓN DE SOLICITUDES*

###  *API Gateway - El Portero Inteligente*
*API Gateway recibe todas las peticiones del frontend (ya protegidas por WAF) y las distribuye según el endpoint invocado:

| *Tipo de Solicitud* | *Endpoint* | *Destino* |
|--------------------|--------------|-------------|
| Crear reclamo | POST /reclamos  | *Lambda-Reclamos* |
| Consultar reclamo | GET /reclamos/{id} | *Lambda-Reclamos* |
| Actualizar reclamo | PUT /reclamos/{id}  | *Lambda-Reclamos* |
| Listar reclamos | GET /reclamos | *Lambda-Reclamos* |
| Generar reportes | GET /reportes  | *Lambda-Reportes* |

###  *Validaciones en API Gateway:*
- Verifica el JWT token de Cognito en cada solicitud.
- Valida el formato de las solicitudes.
- Registra logs de auditoría para cada llamada.


##  *FASE 3: PROCESAMIENTO PRINCIPAL*

###  Lambda-Reclamos
## Propósito: Capturar nuevos reclamos de forma inmediata.
## Acción:

- Recibe la solicitud POST desde API Gateway con los datos del reclamo.
- Valida los datos básicos.
- Envía un mensaje con los datos del reclamo a la cola SQS-Procesamiento para su manejo asíncrono.
- Retorna una respuesta inmediata al usuario (ej. 202 Accepted), indicando que el reclamo fue recibido.


###  *Lambda-Reportes (Analytics & Reports)*

## Propósito: Generar reportes y estadísticas para los funcionarios.
# Acción:

1. Consulta directamente la base de datos DynamoDB con filtros complejos (por fecha, tipo, estado).
2. Procesa y agrega los datos para generar los reportes.
3. Retorna los datos formateados (ej. JSON) al frontend.

##  *FASE 4: PROCESAMIENTO ASÍNCRONO*

###  *SQS-Procesamiento (Cola de Tareas)*
- *Propósito*: Desacoplar la recepción de reclamos de su procesamiento pesado.
- *Beneficios*: El usuario no espera, el sistema es más resiliente y maneja picos de carga sin problemas.
- *Contenido*: Mensajes con la información de cada reclamo enviado por Lambda-Reclamos.

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

3.  ACTUALIZACIÓN EN BASE DE DATOS:
   - Actualiza registro en DynamoDB con nueva información
   - Cambia estado: "PENDIENTE" → "EN_PROCESO"


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


##  *ALMACENAMIENTO Y PERSISTENCIA*
###  *DynamoDB - Base de Datos Principal*
#### *Tabla: Reclamos*
json
{
  "reclamoId": "REC-2025-001234",
  "ciudadanoId": "CIU-12345678",
  "fechaCreacion": "2025-06-06T10:30:00Z",
  "tipo": "SERVICIOS_PUBLICOS",
  "subtipo": "ALUMBRADO_PUBLICO",
  "descripcion": "Poste de luz dañado en Av. Principal",
  "estado": "EN_PROCESO",
  "prioridad": "MEDIA",
  "ubicacion": {
    "direccion": "Av. Principal 123",
    "coordenadas": [-12.0464, -77.0428]
  },
  "funcionarioAsignado": "FUNC-456",
  "fechaVencimiento": "2025-06-20T10:30:00Z",
  "historial": [
    {
      "fecha": "2025-06-06T10:30:00Z",
      "accion": "CREADO",
      "usuario": "CIU-12345678"
    }
  ]
}


##  *MONITOREO Y OBSERVABILIDAD*

###  *CloudWatch*
- *Logs*: Centralizados de todas las funciones Lambda
- *Métricas*: Performance, errores, latencia
- *Alarmas*: Notificaciones cuando hay problemas
- *Dashboards*: Visualización en tiempo real

### *IAM (Identity and Access Management)*
- *Roles específicos* para cada Lambda
- *Políticas de mínimo privilegio*
- *Cross-service permissions* controlados

##  *BENEFICIOS DE ESTA ARQUITECTURA*

###  *Performance:*
- Respuestas inmediatas al usuario
- Procesamiento asíncrono en background
- CDN global para carga rápida

###  *Escalabilidad:*
- Serverless: escala automáticamente
- Sin servidores que gestionar
- Pago por uso real

###  *Seguridad:*
- Autenticación centralizada con Cognito
- Permisos granulares con IAM
- Proteccion de borde con WAF

###  *Costo-Efectividad:*
- Sin infraestructura fija
- Solo pagas por ejecuciones
- Optimización automática de recursos


##  *MÉTRICAS CLAVE A MONITOREAR*

- Tiempo de respuesta API: < 500ms
- Tasa de éxito: > 99.9%
- Reclamos procesados/día: Variable según demanda
- Tiempo promedio de resolución: Por tipo de reclamo
- Satisfacción ciudadana: Encuestas post-resolución
