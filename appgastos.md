# 📋 Documento de Arquitectura y Plan de Desarrollo
> **Proyecto:** Asistente Financiero Personal ("The Godfather")
> **Stack Tecnológico:** Flutter (Frontend) + Supabase (Backend/BaaS)
> **Arquitectura de Estado:** Riverpod / Provider

---

## 1. Resumen Ejecutivo
Aplicativo móvil multiplataforma enfocado en la gestión de finanzas personales y gastos compartidos del hogar. Incorpora mecánicas de gamificación mediante un personaje interactivo, entrada de datos por voz y estrictas medidas de seguridad a nivel de base de datos. La interfaz principal prescinde de texto en sus botones de acción, operando exclusivamente mediante estímulos visuales (iconografía).

---

## 2. Pila Tecnológica Seleccionada

*   **Frontend:** Flutter (Dart) para iOS y Android.
*   **Backend & Base de Datos:** Supabase (PostgreSQL, Auth, Storage).
*   **Reconocimiento de Voz:** Librería nativa `speech_to_text`.
*   **Gráficos y Reportes:** Librería `fl_chart`.
*   **Gestión de Tokens Seguros:** `flutter_secure_storage`.

---

## 3. FASE 1: Infraestructura y Base de Datos (Supabase)

Esta fase establece los cimientos de alta seguridad y la persistencia de datos relacionales para un entorno multiusuario seguro ("inhackeable").

### 3.1 Esquema de Base de Datos
Se implementarán tres tablas principales en PostgreSQL:

| Tabla | Propósito | Campos Clave |
| :--- | :--- | :--- |
| **profiles** | Información del usuario autenticado. | `id` (UUID), `email`, `full_name`, `created_at` |
| **transactions** | Registro de ingresos y egresos. | `id`, `user_id`, `amount`, `concept`, `category`, `transaction_type` (gasto/abono), `target_module` (personal/casa), `created_at` (server-side) |
| **budgets** | Configuración de límites mensuales. | `id`, `user_id`, `limit_amount`, `month_year` |

### 3.2 Arquitectura de Seguridad
*   **Aislamiento de Datos (RLS):** Activación estricta de *Row Level Security* en todas las tablas. Cada fila estará vinculada al `user_id` para garantizar que las consultas solo devuelvan la información del usuario autenticado.
*   **Prevención de Fuerza Bruta:** Configuración de *Rate Limiting* en Supabase Auth. Bloqueo automático de IP y cuenta tras 5 intentos fallidos de inicio de sesión durante 15 minutos.
*   **Sello de Tiempo Inalterable:** El campo `created_at` se calculará obligatoriamente desde el servidor (PostgreSQL) para evitar la manipulación de la fecha/hora desde el dispositivo móvil.

---

## 4. FASE 2: Módulo de Acceso (Login y Registro)

*   **Inicio de Sesión Automático:** Integración de **OAuth2 con Google** para registro e inicio de sesión en un clic capturando únicamente los datos mínimos esenciales.
*   **Inicio de Sesión Manual:** 
    *   Formulario minimalista exigiendo correo y contraseña (mínimo 8 caracteres, alfanumérico y símbolos).
    *   Módulo de recuperación mediante envío de token seguro al correo registrado.

---

## 5. FASE 3: Interfaz de Usuario y Experiencia (UI/UX)

La aplicación sigue un diseño "Pixel Perfect", escalable a cualquier dispositivo y con una filosofía minimalista extrema en sus controles principales.

### 5.1 Dashboard Central
*   **Estado del Personaje:** La pantalla principal se domina por el personaje central. Su estado (neutral, preocupado, enojado) reacciona de forma reactiva al límite de la caja chica configurada.
*   **Controles Flotantes Sin Texto:** 
    *   **Botón Izquierdo (Gasto):** Muestra exclusivamente el asset `01.png` (cuchillo).
    *   **Botón Derecho (Abono):** Muestra exclusivamente el asset `02.png` (mano abierta).

### 5.2 Flujo de Ingreso de Datos (Voz / Manual)
Al interactuar con `01.png` o `02.png`, se despliega un *Bottom Sheet*:
1.  **Motor de Voz:** Si se activa el micrófono, el sistema escucha (ej: "25 soles internet"), el analizador sintáctico aísla el monto (`25.00`) y el concepto (`internet`).
2.  **Modo Manual:** Dos inputs limpios para ingresar el valor y el texto.
3.  **Categorización Automática:** El sistema redirige automáticamente conceptos detectados al módulo correspondiente (ej: "luz" va directamente a Gastos de Casa).

### 5.3 Módulo Gastos de Casa (Balance Inteligente)
*   Panel que suma los ingresos (`02.png`) provenientes del familiar responsable (Padre).
*   Suma de los gastos fijos del hogar.
*   Cálculo en tiempo real: `Saldo Restante = Abonos Recibidos - Total Servicios Pagados`.

### 5.4 Módulo Gastos Personales (Caja Chica)
*   Monitoreo del límite establecido (ej: 200 soles).
*   Barra de progreso visual: Cambia de neutral a alerta (rojo) si el valor excede el 100%.

### 5.5 Reportes e Histórico
*   Dashboard interactivo con gráficos de anillos (`fl_chart`).
*   Filtros mensuales e interruptor (Toggle) para alternar vistas entre histórico de la casa y gastos personales.

---

## 6. FASE 4: Aseguramiento de Calidad (QA) y Pruebas

Para asegurar la robustez requerida, se aplicarán las siguientes matrices de evaluación:

*   **Pruebas de Seguridad:** Ejecución de peticiones con tokens manipulados para confirmar la inviolabilidad de las políticas RLS. Verificación del bloqueo de *endpoints* tras múltiples errores.
*   **Pruebas Lógicas:** Validación del *parser* de voz con diferentes acentos y combinaciones de palabras.
*   **Pruebas de UI:** Verificación de la adaptación responsiva de los assets `01.png` y `02.png` en pantallas de 4 a 6.7 pulgadas sin desbordamientos de diseño.

---

## 7. FASE 5: Compilación y Despliegue

*   **Migración a Producción:** Transición de llaves de desarrollo a llaves de producción en Supabase.
*   **Android:** Generación de `App Bundle (.aab)` con *ProGuard* activado para ofuscación de código nativo.
*   **iOS:** Compilación del archivo `.ipa` validado mediante Xcode para su distribución.