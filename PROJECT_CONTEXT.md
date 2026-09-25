# ORDIVO — CONTEXTO ACTUAL DEL PROYECTO

> Documento de contexto técnico y funcional para continuar el desarrollo de ORDIVO en futuros chats o sesiones.
>
> La fuente de verdad técnica del repositorio sigue siendo este archivo dentro del proyecto Flutter.

---

# 1. ¿Qué es ORDIVO?

ORDIVO es una aplicación de gestión para pequeños negocios.

El objetivo es disponer de un MVP funcional que pueda probarse con negocios reales antes de desarrollar funciones más avanzadas o intentar monetizar el producto.

La aplicación centraliza:

- Ventas
- Caja
- Stock
- Productos
- Categorías
- Clientes
- Gastos
- Dashboard y resumen del negocio
- Movimientos de stock

Concepto de marca:

**ORDIVO — Tu negocio, en orden.**

El nombre comercial actual y definitivo del producto es:

**ORDIVO**

El nombre técnico histórico del proyecto/repositorio continúa siendo **BizzFlow** en aquellos lugares donde no fue necesario modificarlo.

---

# 2. Tecnología

Proyecto desarrollado con:

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting
- Git
- GitHub

Editor principal:

- Cursor

Sistema de desarrollo:

- Windows
- PowerShell

Ruta local:

```text
C:\Users\barbitaaa\PYTHON\BizzFlow

```

Repositorio GitHub:

```text
https://github.com/santiagoabelfraquelli-png/BizzFlow

```

Branch:

```text
main

```

Firebase Project ID:

```text
bizzflow-f99c0

```

IMPORTANTE:

El nombre comercial de la aplicación es **ORDIVO**.

No cambiar sin autorización explícita:

- repositorio GitHub
- Firebase Project ID
- applicationId
- namespace
- estructura de Firestore
- arquitectura general

---

# 3. Rebranding BizzFlow → ORDIVO

El proyecto originalmente utilizaba el nombre:

```text
BizzFlow

```

El nombre comercial fue cambiado a:

**ORDIVO**

El rebranding fue realizado, compilado y probado correctamente.

Cambios principales:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/business_setup_screen.dart`
- `lib/screens/profile_screen.dart`
- `web/index.html`
- `web/manifest.json`
- `android/app/src/main/AndroidManifest.xml`

Se actualizaron imports, títulos y textos visibles relacionados con la marca.

No se modificaron innecesariamente:

- Firebase Project ID
- applicationId
- namespace
- arquitectura Firestore
- arquitectura multi-negocio

Commit de rebranding:

```text
04465f6
Rebrand app from BizzFlow to ORDIVO

```

El commit fue enviado correctamente a `origin/main`.

---

# 4. Estado técnico del rebranding

Se ejecutó:

```text
flutter pub get

```

Resultado:

```text
Got dependencies!

```

Flutter informó que existen paquetes con versiones nuevas incompatibles con las restricciones actuales.

No actualizar automáticamente estos paquetes.

También se ejecutó:

```text
flutter analyze

```

Resultado:

```text
No issues found!

```

El proyecto fue ejecutado correctamente en Chrome.

Conclusión:

**El rebranding a ORDIVO fue validado y no rompió la aplicación.**

---

# 5. Aplicación web

ORDIVO dispone actualmente de una versión web funcional.

Build generado mediante:

```text
flutter build web

```

Salida:

```text
build\web

```

La versión web fue probada localmente mediante un servidor HTTP.

También fue publicada mediante Firebase Hosting.

Hosting actual:

```text
https://bizzflow-f99c0.web.app

```

Comando utilizado para publicar:

```text
firebase deploy --only hosting

```

IMPORTANTE:

La versión publicada NO se actualiza automáticamente cuando se modifica el código.

Después de realizar cambios que deban publicarse:

```text
flutter build web
firebase deploy --only hosting

```

No realizar deploy sin autorización explícita del usuario.

---

# 6. PWA

La versión web fue configurada como PWA.

Características implementadas:

- `display: standalone`
- manifest configurado
- nombre ORDIVO
- iconos web
- iconos maskable
- colores de marca
- instalación desde Chrome
- icono correcto de ORDIVO

Icono principal:

```text
assets/icon/ordivo_icon.png

```

Configuración de iconos realizada mediante:

```text
flutter_launcher_icons

```

Configuración actual:

```yaml
flutter_launcher_icons:
  android: true
  web:
    generate: true
    image_path: "assets/icon/ordivo_icon.png"
    background_color: "#FFF8FA"
    theme_color: "#E8A6B8"
  image_path: "assets/icon/ordivo_icon.png"

```

La PWA fue probada y el icono correcto apareció en el proceso de instalación de Chrome.

No rehacer esta configuración salvo que sea necesario.

---

# 7. Arquitectura multi-negocio

ORDIVO utiliza una arquitectura multi-negocio.

Cada usuario se relaciona con un negocio mediante:

```text
users/{uid}.businessId

```

Los documentos operativos utilizan:

```text
businessId

```

para separar los datos de cada negocio.

La colección principal del negocio es:

```text
businesses/{businessId}

```

Actualmente contiene información como:

- `name`
- `ownerId`
- `createdAt`

Objetivo fundamental:

**Un usuario nunca debe poder acceder a los datos de otro negocio.**

---

# 8. Colecciones de Firestore

Actualmente se utilizan:

```text
users
businesses
categories
products
sales
customers
expenses
cash_movements
stock_movements

```

Las colecciones operativas relacionadas con el negocio utilizan `businessId`.

---

# 9. Seguridad de Firestore

La seguridad está basada en:

1. Firebase Authentication.
2. Identificación del usuario autenticado.
3. Relación entre usuario y negocio.
4. Validación de `businessId`.
5. Validación de `ownerId`.

Las reglas de Firestore fueron revisadas y endurecidas.

La lógica de seguridad incluye una comprobación equivalente a:

```text
ownsBusiness(businessId)

```

Esta comprobación verifica que:

- el usuario esté autenticado;
- el negocio exista;
- el `ownerId` del negocio corresponda al usuario autenticado.

En actualizaciones de negocios también se controla la consistencia de los datos existentes y nuevos y se evita modificar arbitrariamente el propietario.

Las reglas fueron desplegadas mediante:

```text
firebase deploy --only firestore:rules

```

También se realizó una prueba utilizando dos cuentas diferentes.

Resultado:

**El usuario B no puede acceder a los datos del negocio del usuario A.**

Esta separación es una parte crítica de la arquitectura y no debe debilitarse.

---

# 10. Configuración inicial del negocio

Archivo principal:

```text
lib/screens/business_setup_screen.dart

```

Flujo:

1. El usuario inicia sesión.
2. Se consulta `users/{uid}`.
3. Si no existe `businessId`, aparece la configuración inicial.
4. El usuario introduce el nombre del negocio.
5. Se crea `businesses/{businessId}`.
6. Se guarda el `businessId` en `users/{uid}`.
7. Se abre `BusinessHomeScreen`.

La creación del negocio asigna:

```text
ownerId = request.auth.uid

```

---

# 11. Panel principal

El panel principal contiene:

- Dashboard
- Ventas
- Caja
- Stock
- Productos
- Categorías
- Clientes
- Gastos

El panel fue rediseñado visualmente.

Incluye:

- Header moderno
- Tarjetas
- Gradientes
- Iconos
- Sombras
- Animaciones
- Hover en web
- Diseño responsive
- Modo oscuro
- Diferenciación visual entre módulos

El diseño fue probado correctamente en Chrome.

---

# 12. Dashboard

Archivo:

```text
lib/screens/dashboard_screen.dart

```

Muestra:

- Ventas del día
- Cantidad de ventas
- Gastos del día
- Resultado
- Productos sin stock
- Productos con stock bajo

Criterio actual:

```text
<= 0       → sin stock
> 0 <= 5   → stock bajo
> 5        → disponible

```

Este criterio funciona correctamente.

**No modificarlo salvo solicitud explícita.**

Consultas principales:

```text
sales
expenses
products

```

Todas filtradas mediante:

```text
businessId

```

Índices utilizados:

```text
Sales:
businessId Asc + createdAt Asc

Expenses:
businessId Asc + date Asc

```

El Dashboard fue probado correctamente.

---

# 13. Ventas

Archivo:

```text
lib/screens/sales_screen.dart

```

Características:

- Selección de productos
- Carrito
- Cantidad
- Precio
- Total
- Registro de venta
- Descuento automático de stock
- Registro de movimiento de stock
- Selección de cliente

La venta utiliza una transacción de Firestore.

Durante la operación se vuelve a comprobar la pertenencia del cliente y de los productos al negocio.

La venta almacena:

```text
businessId

```

La operación actualiza de forma atómica:

- venta
- stock
- movimiento de stock

La pantalla de Ventas fue rediseñada y probada correctamente.

---

# 14. Historial de ventas

Archivo:

```text
lib/screens/sales_history_screen.dart

```

Permite consultar las ventas del negocio.

La consulta está filtrada mediante:

```text
businessId

```

Es una pantalla principalmente de lectura.

---

# 15. Stock

Archivo:

```text
lib/screens/stock_screen.dart

```

Permite:

- Ver productos
- Ver cantidad disponible
- Ver categoría
- Ver unidad
- Ver estado
- Agregar stock
- Actualizar stock mediante transacción
- Consultar movimientos

Unidades disponibles:

- unidad
- kg
- g
- litro
- ml

La operación de agregar stock verifica que el producto pertenezca al negocio actual.

El historial utiliza:

```text
stock_movements

```

La pantalla de Stock fue rediseñada y probada correctamente.

---

# 16. Productos

Archivo:

```text
lib/screens/products_screen.dart

```

Permite:

- Crear productos
- Listar productos
- Editar productos
- Eliminar productos
- Seleccionar categoría
- Definir precio
- Definir stock inicial
- Definir unidad
- Activar/desactivar productos
- Registrar movimientos de stock
- Consultar historial relacionado con stock

Cada producto utiliza:

```text
businessId

```

La pantalla de Productos fue rediseñada y probada correctamente.

La lógica de Productos y Stock debe mantener siempre la separación mediante `businessId`.

---

# 17. Categorías

Archivo:

```text
lib/screens/categories_screen.dart

```

Permite:

- Crear categorías
- Listar categorías
- Eliminar categorías

Las categorías se ordenan alfabéticamente.

Cada categoría pertenece a un:

```text
businessId

```

---

# 18. Clientes

Archivo:

```text
lib/screens/customers_screen.dart

```

Permite:

- Crear clientes
- Listarlos
- Editarlos
- Eliminarlos

Datos:

- Nombre obligatorio
- Teléfono opcional
- Email opcional
- `businessId`
- `createdAt`

Archivo relacionado:

```text
lib/screens/customer_detail_screen.dart

```

El detalle del cliente verifica que el cliente pertenezca al negocio actual.

Las ventas relacionadas se consultan filtrando por:

```text
businessId
customerId

```

La relación con ventas se mantiene simple dentro del MVP.

---

# 19. Gastos

Archivo:

```text
lib/screens/expenses_screen.dart

```

Permite:

- Crear gastos
- Listarlos
- Editarlos
- Eliminarlos
- Seleccionar categoría
- Definir importe
- Definir fecha

Categorías actuales:

- Insumos
- Alquiler
- Servicios
- Transporte
- Sueldos
- Mantenimiento
- Otros

Los gastos aparecen correctamente en:

- Dashboard
- Caja

Todos los gastos pertenecen a un:

```text
businessId

```

---

# 20. Caja

Archivo:

```text
lib/screens/cash_screen.dart

```

La caja utiliza:

```text
cash_movements

```

Tipos:

```text
income
expense

```

Origen:

```text
manual
sale
expense

```

Una venta genera un ingreso de caja.

Un gasto genera un egreso.

También se pueden registrar movimientos manuales.

Fórmula actual:

```text
Saldo =
ventas
+ ingresos manuales
- gastos
- egresos manuales

```

Todas las consultas están filtradas mediante:

```text
businessId

```

La Caja fue probada correctamente.

---

# 21. Movimientos de stock

Colección:

```text
stock_movements

```

Los movimientos mantienen un historial de cambios de stock.

Información utilizada:

- `businessId`
- `productId`
- `productName`
- `type`
- `quantity`
- `stockBefore`
- `stockAfter`
- `note`
- `createdAt`

Tipos principales:

```text
entry

```

y movimientos relacionados con ventas.

Las operaciones de venta y movimientos relevantes utilizan transacciones de Firestore.

---

# 22. Perfil

Archivo:

```text
lib/screens/profile_screen.dart

```

El perfil recibe:

```text
businessId

```

Permite gestionar aspectos del usuario y configuración local.

Funciones actuales:

- Cambio de nombre visible
- Actualización de `displayName`
- Envío de email de verificación
- Recuperación/cambio de contraseña
- Recordar inicio de sesión
- Configuración de apariencia
- Modo oscuro
- Cierre de sesión
- Reinicio de datos operativos del negocio

El reinicio de datos solicita escribir:

```text
REINICIAR

```

y elimina los documentos operativos correspondientes al `businessId`.

No elimina:

- cuenta del usuario
- negocio
- propietario

El perfil fue revisado durante la auditoría de seguridad multi-negocio.

No requiere cambios actualmente.

---

# 23. Auditoría multi-negocio

Se realizó una revisión módulo por módulo para comprobar que cada pantalla utilice correctamente:

```text
businessId

```

Se revisaron:

- Autenticación
- Configuración del negocio
- Dashboard
- Ventas
- Historial de ventas
- Stock
- Productos
- Categorías
- Clientes
- Detalle de cliente
- Gastos
- Caja
- Perfil
- Movimientos de stock

Resultado:

**La arquitectura actual utiliza correctamente** `businessId` **en las operaciones principales.**

También se realizó una prueba con dos usuarios/negocios.

Resultado:

**El usuario B no puede ver los datos del negocio A.**

La seguridad de Firestore complementa las comprobaciones realizadas desde Flutter.

---

# 24. Prueba funcional completa

Se realizó una prueba funcional desde cero.

Negocio:

```text
Almacén Prueba

```

Categoría:

```text
Bebidas

```

Producto:

```text
Coca Cola

```

Stock inicial:

```text
5

```

Precio:

```text
$1000

```

Venta:

```text
2 unidades

```

Stock restante:

```text
3

```

Gasto:

```text
$500

```

Resultados:

```text
Ventas:   $2000
Gastos:   $500
Resultado: $1500

```

Caja:

```text
Ingresos: $2000
Egresos:  $500
Saldo:    $1500

```

También se comprobó:

- Dashboard
- Stock
- Productos
- Ventas
- Caja
- Gastos
- Clientes
- Movimientos

Resultado:

**El flujo principal del MVP funciona correctamente.**

---

# 25. Validación técnica

Se ejecutó:

```text
flutter pub get

```

Resultado:

```text
Got dependencies!

```

Se ejecutó:

```text
flutter analyze

```

Resultado:

```text
No issues found!

```

Se ejecutó:

```text
flutter build web

```

Resultado:

**Correcto.**

Se probó la aplicación en Chrome.

Resultado:

**Correcto.**

Se generó:

```text
build\web

```

Se publicó correctamente en Firebase Hosting.

---

# 26. Git

Repositorio:

```text
https://github.com/santiagoabelfraquelli-png/BizzFlow

```

Branch:

```text
main

```

Checkpoint importante:

```text
a2c5029

```

Mensaje:

```text
Finalize MVP redesign and validation

```

Checkpoint de rebranding:

```text
04465f6

```

Mensaje:

```text
Rebrand app from BizzFlow to ORDIVO

```

El commit de rebranding fue enviado correctamente a:

```text
origin/main

```

Regla:

**No realizar commits ni push sin autorización explícita del usuario.**

---

# 27. Respaldo

Se realizó un respaldo completo del proyecto antes de continuar con esta etapa.

El respaldo fue generado desde:

```text
C:\Users\barbitaaa\PYTHON\BizzFlow

```

mediante un archivo ZIP.

El respaldo debe conservarse como punto de recuperación antes de realizar cambios importantes.

---

# 28. Identidad visual

Nombre comercial:

**ORDIVO**

Slogan:

**Tu negocio, en orden.**

Color principal utilizado:

```text
#E8A6B8

```

Color de fondo principal:

```text
#FFF8FA

```

Icono principal:

```text
assets/icon/ordivo_icon.png

```

El icono ya fue configurado para:

- Web
- PWA
- Android

No reemplazarlo sin autorización.

---

# 29. Estado actual del MVP

ORDIVO actualmente cuenta con:

- Firebase configurado
- Firebase Authentication
- Firestore
- Seguridad multi-negocio
- Dashboard
- Ventas
- Historial de ventas
- Caja
- Stock
- Productos
- Categorías
- Clientes
- Gastos
- Movimientos de stock
- Perfil
- Modo oscuro
- Diseño responsive
- Rediseño visual
- PWA
- Icono personalizado
- Build web
- Firebase Hosting
- GitHub sincronizado

El MVP principal se encuentra funcional y validado.

---

# 30. Estado actual de publicación

URL pública:

```text
https://bizzflow-f99c0.web.app

```

La aplicación puede utilizarse desde navegador y puede instalarse como PWA en navegadores compatibles.

Para publicar una nueva versión:

```text
flutter build web
firebase deploy --only hosting

```

Siempre solicitar autorización antes del deploy.

---

# 31. Prioridad actual

La prioridad actual es:

**Continuar mejorando ORDIVO sin romper la funcionalidad existente.**

Las mejoras deben surgir de necesidades reales detectadas durante las pruebas o al mostrar la aplicación a negocios.

Áreas posibles:

- UI/UX
- Diseño visual
- Usabilidad
- Responsive
- Pruebas
- Correcciones
- Mejoras de módulos existentes
- Preparación para negocios reales

No agregar funcionalidades grandes de forma especulativa.

---

# 32. Funcionalidades que NO deben agregarse automáticamente

No agregar sin solicitud explícita:

- Pagos
- Suscripciones
- IA
- Reportes complejos
- Proveedores
- Empleados
- Facturación electrónica
- Estadísticas avanzadas
- Multiusuario avanzado
- Integraciones comerciales
- Funciones empresariales grandes

Primero validar la necesidad.

---

# 33. Reglas de trabajo

## Regla 1 — Preservar funcionalidad

Antes de modificar cualquier pantalla:

- No romper Firebase.
- No romper Firestore.
- No romper `businessId`.
- No romper navegación.
- No eliminar funcionalidades existentes.
- No debilitar reglas de seguridad.
- No cambiar arquitectura innecesariamente.

---

## Regla 2 — Inspeccionar antes de modificar

Antes de realizar cambios:

1. Revisar el archivo existente.
2. Entender cómo funciona actualmente.
3. Identificar dependencias.
4. Revisar `businessId`.
5. Revisar consultas Firestore.
6. Recién después modificar.

No asumir que el código funciona de una determinada manera sin comprobarlo.

---

## Regla 3 — Archivos completos

Cuando el usuario solicite modificar un archivo:

**Preferir entregar el archivo completo listo para reemplazar.**

No entregar fragmentos pequeños cuando puedan generar errores de reemplazo.

---

## Regla 4 — Validación

Después de cada modificación importante:

1. Reemplazar el archivo.
2. Ejecutar:

```text
flutter analyze

```

1. Probar la funcionalidad.
2. Probar en Chrome cuando corresponda.
3. Revisar:

```text
git status

```

1. Actualizar este `PROJECT_CONTEXT.md` cuando exista una decisión importante.

No hacer commit automáticamente.

No hacer push automáticamente.

No hacer deploy automáticamente.

---

## Regla 5 — Git

Antes de modificar:

```text
git status

```

Después de modificar:

```text
git status

```

Commit solamente con autorización explícita.

Push solamente con autorización explícita.

No reinicializar Git.

No crear otro repositorio.

---

## Regla 6 — Firebase

No cambiar sin autorización:

- Firebase Project ID
- Firebase Authentication
- estructura Firestore
- reglas de seguridad
- índices
- configuración existente

Si una modificación requiere tocar Firebase, explicar primero qué se va a cambiar y por qué.

---

## Regla 7 — Seguridad

`businessId` es fundamental.

Toda nueva funcionalidad relacionada con datos del negocio debe analizar:

- lectura
- creación
- actualización
- eliminación
- reglas Firestore
- pertenencia al negocio

No asumir que ocultar información en Flutter es suficiente.

La seguridad real debe mantenerse también en Firestore.

---

## Regla 8 — Cambios pequeños

Preferencia de trabajo:

**hacer un cambio → probar → confirmar → continuar.**

No realizar muchos cambios simultáneos cuando sea necesario validar comportamiento.

---

## Regla 9 — Explicaciones

Explicar de forma:

- clara
- directa
- paso a paso
- en español
- sin asumir conocimientos avanzados

Si existe un problema, primero identificarlo antes de proponer cambios grandes.

---

# 34. Instrucciones para futuros agentes

Antes de modificar cualquier cosa:

1. Revisar `git status`.
2. Leer `PROJECT_CONTEXT.md`.
3. Revisar el código existente.
4. Preservar cambios locales.
5. No reinicializar el proyecto.
6. No crear otro repositorio.
7. No cambiar Firebase Project ID.
8. No cambiar applicationId.
9. No cambiar namespace.
10. No romper `businessId`.
11. No debilitar la seguridad.
12. No hacer commit sin autorización.
13. No hacer push sin autorización.
14. No hacer deploy sin autorización.
15. Hacer cambios pequeños y verificables.
16. Ejecutar las pruebas apropiadas.
17. Mantener este archivo actualizado cuando se tome una decisión importante.

---

# 35. Estado final

ORDIVO es actualmente un:

**MVP funcional de gestión para pequeños negocios, conectado a Firebase, con autenticación, Firestore, seguridad multi-negocio, módulos principales funcionando, versión web publicada y PWA configurada.**

Estado:

- Firebase configurado
- Authentication funcionando
- Firestore funcionando
- Seguridad multi-negocio revisada
- Aislamiento entre negocios probado
- Dashboard funcionando
- Ventas funcionando
- Historial de ventas funcionando
- Caja funcionando
- Stock funcionando
- Productos funcionando
- Categorías funcionando
- Clientes funcionando
- Gastos funcionando
- Movimientos de stock funcionando
- Perfil funcionando
- Panel principal rediseñado
- Dashboard rediseñado
- Ventas rediseñadas
- Productos rediseñados
- Stock rediseñado
- Modo oscuro funcionando
- Diseño responsive
- `flutter analyze` sin problemas
- Chrome probado correctamente
- Build web generado
- Firebase Hosting configurado
- PWA configurada
- Icono ORDIVO configurado
- Rebranding terminado
- Git sincronizado con GitHub
- Respaldo completo realizado

Pendiente:

- Continuar mejoras de UI/UX según necesidad
- Probar ORDIVO con negocios reales
- Recopilar feedback real
- Corregir problemas detectados durante pruebas reales
- Definir estrategia comercial/publicación definitiva

---

# 36. Nombre definitivo

**ORDIVO**

**Tu negocio, en orden.**

No volver a utilizar **BizzFlow** como nombre visible de la aplicación.

El nombre BizzFlow puede permanecer únicamente en identificadores técnicos existentes que no deben modificarse sin autorización.