# BizzFlow — PROJECT_CONTEXT.md

> **Fuente de verdad del proyecto.**
>
> Antes de realizar cambios, leer este archivo completo y asumir que describe el estado actual del repositorio.

**Última actualización:** 2026-09-23

---

## 1. Objetivo del proyecto

BizzFlow es una aplicación de gestión para pequeños negocios.

El objetivo actual es disponer de un MVP funcional, simple y visualmente claro que pueda probarse con negocios reales antes de incorporar funcionalidades más avanzadas.

El proyecto está desarrollado con:

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Git / GitHub
- Cursor como editor

El usuario es principiante/intermedio en programación y prefiere soluciones completas, concretas y listas para reemplazar.

---

# 2. Proyecto local

Ruta:

`C:\Users\barbitaaa\PYTHON\BizzFlow`

Nombre del paquete:

`bizzflow`

Repositorio:

GitHub privado de BizzFlow.

Rama principal:

`main`

---

# 3. Arquitectura

La aplicación utiliza una arquitectura multi-negocio.

Cada usuario puede estar asociado a un negocio mediante:

`users/{userId}`

con el campo:

`businessId`

Los datos de cada módulo utilizan `businessId` para separar la información entre distintos negocios.

### Regla fundamental

Un negocio nunca debe poder acceder a los datos de otro negocio.

Todas las operaciones de Firestore que manejan datos del negocio deben respetar esta separación.

---

# 4. Flujo principal actual

El flujo general del MVP es:

1. Crear/iniciar sesión.
2. Configurar negocio.
3. Acceder al panel principal.
4. Dashboard.
5. Ventas.
6. Caja.
7. Stock.
8. Categorías.
9. Productos.
10. Clientes.
11. Gastos.
12. Perfil y configuración.

Todos estos módulos están implementados.

La etapa actual del proyecto se encuentra enfocada en:

- Estabilidad del MVP.
- Consistencia visual.
- Experiencia de usuario.
- Seguridad de Firestore.
- Integración entre módulos.
- Validación mediante pruebas reales.
- Preparación para probar BizzFlow con un negocio real.

No se deben comenzar funcionalidades grandes sin necesidad.

---

# 5. Firebase Authentication

Firebase Authentication está configurado para:

- Registro.
- Inicio de sesión.
- Verificación de email.
- Recuperación de contraseña.
- Persistencia de sesión.

Las contraseñas no se almacenan en texto plano en Firestore.

---

# 6. Firestore

Colecciones utilizadas actualmente:

- `users`
- `businesses`
- `categories`
- `products`
- `sales`
- `customers`
- `expenses`
- `cash_movements`
- `stock_movements`

Las colecciones que contienen información de negocio utilizan:

`businessId`

La seguridad se basa en comprobar que el usuario autenticado sea propietario del negocio indicado por ese `businessId`.

---

# 7. Módulos implementados

## 7.1 Categorías

Archivo:

`lib/screens/categories_screen.dart`

Funcionalidades:

- Listar categorías.
- Crear categorías.
- Eliminar categorías.
- Orden alfabético.
- Filtrado por `businessId`.
- Persistencia en Firestore.
- Integración con Productos.

Campos:

- `businessId`
- `name`
- `active`
- `createdAt`

### Estado

**Funcional y probado.**

Se comprobó:

- Creación.
- Eliminación.
- Persistencia.
- Visualización.
- Modo oscuro.
- Relación con Productos.

---

# 7.2 Productos

Archivo:

`lib/screens/products_screen.dart`

Funcionalidades:

- Crear productos.
- Listar productos.
- Eliminar productos.
- Seleccionar categoría.
- Precio.
- Stock inicial.
- Unidad.
- Filtrado por `businessId`.
- Registro de movimientos de stock.

Unidades disponibles:

- unidad
- kg
- g
- litro
- ml

Campos principales:

- `businessId`
- `name`
- `categoryId`
- `categoryName`
- `price`
- `stock`
- `unit`
- `active`
- `createdAt`

### Movimientos de stock

La creación y modificación de stock genera registros en:

`stock_movements`

Campos utilizados:

- `businessId`
- `productId`
- `productName`
- `type`
- `quantity`
- `stockBefore`
- `stockAfter`
- `note`
- `createdAt`

Tipos actuales:

- `initial`
- `entry`
- `adjustment_in`
- `adjustment_out`
- `sale`

### Historial

Los movimientos se presentan con títulos como:

- Stock inicial
- Entrada de stock
- Ajuste de entrada
- Ajuste de salida
- Venta

### Rediseño visual

La pantalla fue rediseñada manteniendo la lógica de negocio existente.

Incluye:

- Mejor jerarquía visual.
- Tarjetas modernas.
- Mejor organización.
- Espaciado consistente.
- Iconografía renovada.
- Diseño responsive.
- Adaptación a Chrome.
- Acciones de producto consistentes con el tema.

Los botones utilizan el color principal de la aplicación.

En modo oscuro se utiliza una versión oscurecida del mismo color principal para conservar la identidad visual.

### Estado

**Funcional, probado y visualmente rediseñado.**

Se comprobó:

- Creación de producto.
- Stock inicial.
- Modificación de stock.
- Eliminación.
- Categorías.
- Historial de movimientos.
- Persistencia.
- Modo oscuro.

---

# 7.3 Ventas

Archivo:

`lib/screens/sales_screen.dart`

Funcionalidades:

- Listar productos.
- Agregar productos al carrito.
- Incrementar cantidades.
- Eliminar productos.
- Calcular total.
- Confirmar venta.
- Descontar stock.
- Registrar venta.
- Registrar movimiento de stock.

La venta utiliza una transacción de Firestore para actualizar el stock y registrar los movimientos correspondientes.

Campos principales de una venta:

- `businessId`
- `items`
- `total`
- `createdAt`

Cada item contiene:

- `productId`
- `productName`
- `quantity`
- `unit`
- `unitPrice`
- `subtotal`

### Movimiento de stock por venta

Al vender un producto se crea un registro en `stock_movements` con:

- `type: sale`
- cantidad vendida.
- stock resultante.
- producto.
- negocio.
- fecha.
- nota `Venta`.

### Rediseño visual

La pantalla fue rediseñada visualmente manteniendo la lógica existente.

Incluye:

- Carrito mejor organizado.
- Productos mejor presentados.
- Totales destacados.
- Botones renovados.
- Tarjetas.
- Espaciado.
- Iconografía.
- Diseño responsive.
- Mejor experiencia de usuario.

### Estado

**Funcional, integrado, probado y visualmente rediseñado.**

Se comprobó:

- Venta.
- Cálculo del total.
- Descuento de stock.
- Registro de venta.
- Registro del movimiento de stock.
- Actualización del Dashboard.
- Integración con Caja.

---

# 7.4 Historial de ventas

Archivo:

`lib/screens/sales_history_screen.dart`

La pantalla permite consultar las ventas registradas.

Fue adaptada al sistema visual actual y al tema oscuro.

### Estado

**Funcional y probado.**

---

# 7.5 Stock

Archivo:

`lib/screens/stock_screen.dart`

Funcionalidades:

- Ver stock.
- Mostrar categoría.
- Mostrar unidad.
- Mostrar estado.
- Agregar stock.
- Actualización mediante transacción Firestore.
- Registrar movimiento de stock.

### Estados de stock

El criterio actual es:

- `<= 0`: Sin stock.
- `1 a 5`: Stock bajo.
- `> 5`: Disponible.

Este criterio NO debe modificarse salvo solicitud explícita.

### Movimiento al agregar stock

Cuando se agrega stock se registra:

`type: entry`

El movimiento contiene información del stock resultante y del producto.

### Rediseño visual

La pantalla fue rediseñada con:

- Encabezado.
- Resumen general.
- Cantidad total de productos.
- Productos disponibles.
- Productos con stock bajo.
- Productos sin stock.
- Tarjetas modernas.
- Indicadores de estado.
- Mejor presentación de cantidades y unidades.
- Modal de agregar stock.
- Diseño responsive.
- Adaptación de columnas en Chrome.
- Bordes redondeados.
- Sombras.
- Iconografía.

### Estado

**Funcional, probado y visualmente rediseñado.**

Se comprobó:

- Consulta mediante `businessId`.
- Orden alfabético.
- Estados de stock.
- Agregar stock.
- Transacción Firestore.
- Registro de movimiento.
- Persistencia.

---

# 7.6 Clientes

Archivo:

`lib/screens/customers_screen.dart`

Funcionalidades:

- Crear cliente.
- Listar clientes.
- Editar cliente.
- Eliminar cliente.
- Abrir detalle de cliente.

Datos:

- Nombre obligatorio.
- Teléfono opcional.
- Email opcional.
- `businessId`
- `createdAt`

Actualmente los clientes todavía no están vinculados directamente con las ventas.

Esto es intencional para mantener el MVP simple.

### Detalle de cliente

Archivo relacionado:

`lib/screens/customer_detail_screen.dart`

Se corrigió la adaptación al tema oscuro para evitar fondos blancos y colores incorrectos.

### Estado

**Funcional y probado.**

Se comprobó:

- Crear.
- Visualizar.
- Editar.
- Eliminar.
- Persistencia.
- Detalle.
- Modo oscuro.

---

# 7.7 Gastos

Archivo:

`lib/screens/expenses_screen.dart`

Funcionalidades:

- Crear gasto.
- Editar gasto.
- Eliminar gasto.
- Listar gastos.
- Mostrar total.
- Ordenar por fecha.
- Filtrar por período.
- Categorías de gastos.
- Fecha.
- Filtrado por `businessId`.

Categorías actuales:

- Insumos
- Alquiler
- Servicios
- Transporte
- Sueldos
- Mantenimiento
- Otros

Campos:

- `businessId`
- `description`
- `amount`
- `category`
- `date`
- `createdAt`

### Estado

**Funcional, integrado y probado.**

Se comprobó:

- Creación.
- Edición.
- Eliminación.
- Filtros.
- Persistencia.
- Dashboard.
- Caja.
- Modo oscuro.

---

# 7.8 Caja

Archivo:

`lib/screens/cash_screen.dart`

La Caja utiliza:

`cash_movements`

Cada movimiento manual contiene:

- `businessId`
- `type`
- `amount`
- `description`
- `date`
- `createdAt`
- `source`

Tipos:

- `income`
- `expense`

Fuentes:

- `manual`
- `sale`
- `expense`

### Funcionamiento

La Caja obtiene:

- Ventas como ingresos.
- Gastos como egresos.
- Movimientos manuales como ingresos o egresos.

Cálculo:

**Saldo = ventas + ingresos manuales - gastos - egresos manuales**

La pantalla muestra:

- Saldo actual.
- Ingresos.
- Egresos.
- Lista de movimientos.

Permite crear:

- Ingresos manuales.
- Egresos manuales.

Cada movimiento permite indicar:

- Tipo.
- Descripción.
- Monto.
- Fecha.

### Estado

**Funcional, integrado y probado.**

Se comprobó:

- Apertura.
- Carga de datos.
- Movimientos manuales.
- Actualización del saldo.
- Visualización de movimientos.
- Integración con ventas.
- Integración con gastos.
- Persistencia.
- Modo oscuro.

También se realizó una prueba controlada con:

- Venta: `$10.000`
- Gasto: `$2.000`
- Ingreso manual: `$5.000`
- Egreso manual: `$1.000`

Resultado esperado:

- Ingresos: `$15.000`
- Egresos: `$3.000`
- Saldo: `$12.000`

El resultado fue correcto.

---

# 7.9 Dashboard

Archivo:

`lib/screens/dashboard_screen.dart`

El Dashboard muestra:

- Ventas de hoy.
- Cantidad de ventas.
- Gastos de hoy.
- Resultado del día.
- Productos sin stock.
- Productos con stock bajo.

Las consultas utilizan `businessId`.

### Índices

Se utilizan índices compuestos para:

#### Sales

- `businessId` Ascending
- `createdAt` Ascending

#### Expenses

- `businessId` Ascending
- `date` Ascending

### Rediseño visual

Incluye:

- Encabezado.
- Tarjetas de métricas.
- Iconos.
- Información diferenciada.
- Tarjetas de stock.
- Diseño responsive.
- Bordes redondeados.
- Sombras.
- Animaciones y transiciones.

### Estado

**Funcional, probado y visualmente rediseñado.**

---

# 7.10 Panel principal

Archivo:

`lib/screens/business_setup_screen.dart`

Contiene:

- Configuración inicial.
- Creación del negocio.
- Asociación del negocio al usuario.
- `BusinessHomeScreen`.
- Panel principal.
- Navegación hacia los módulos.

Módulos disponibles:

- Dashboard.
- Ventas.
- Caja.
- Stock.
- Categorías.
- Productos.
- Clientes.
- Gastos.

Cada módulo recibe el `businessId`.

### Rediseño visual

Incluye:

- Encabezado de bienvenida.
- Tarjetas.
- Iconos.
- Colores diferenciados.
- Bordes redondeados.
- Sombras.
- Animaciones.
- Efectos de interacción.
- Diseño responsive.
- `LayoutBuilder`.

### Estado

**Funcional, probado y visualmente rediseñado.**

---

# 7.11 Perfil y configuración

Archivo:

`lib/screens/profile_screen.dart`

Incluye:

- Información del usuario.
- Información del negocio.
- Configuración.
- Tema.
- Reinicio de datos.

## Reiniciar datos

Permite eliminar registros del `businessId` actual de:

- `sales`
- `expenses`
- `cash_movements`
- `products`
- `customers`
- `categories`
- `stock_movements`

Las consultas utilizan:

`businessId`

Las eliminaciones se realizan mediante batches de hasta 450 documentos.

### Estado

**Funcional y probado.**

Se verificó que el reinicio elimina correctamente los datos pertenecientes al negocio.

---

# 8. Tema visual

BizzFlow cuenta con:

- Tema claro.
- Tema oscuro.

El tema oscuro ya está implementado y validado en las pantallas actuales.

### Criterios

- Mantener identidad visual.
- Evitar fondos blancos incorrectos.
- Mantener color principal.
- Oscurecer el color principal cuando sea necesario en modo oscuro.
- Mantener legibilidad.
- Mantener contraste.
- Evitar cambiar innecesariamente la gama cromática.

### Preferencias

La aplicación cuenta con servicios relacionados con preferencias y tema:

- `lib/services/app_preferences.dart`
- `lib/services/theme_controller.dart`

Estos archivos forman parte del estado actual del proyecto y no deben eliminarse.

---

# 9. Seguridad de Firestore

Las reglas protegen:

- `users`
- `businesses`
- `categories`
- `products`
- `sales`
- `customers`
- `expenses`
- `cash_movements`
- `stock_movements`

Los datos del negocio deben verificar:

1. Usuario autenticado.
2. `businessId` presente.
3. El negocio correspondiente pertenece al usuario autenticado.

### Regla fundamental

Un usuario nunca debe poder leer, crear, modificar o eliminar datos asociados a otro negocio.

### Stock movements

`stock_movements` permite:

- Crear.
- Leer.
- Eliminar.

siempre que el negocio correspondiente pertenezca al usuario autenticado.

Esto permite que **Reiniciar datos** elimine correctamente los movimientos de stock sin permitir acceso entre negocios.

### Publicación

Las modificaciones de reglas deben publicarse con:

```powershell
firebase deploy --only firestore:rules

```

Una modificación de reglas no se considera terminada hasta confirmar que fue publicada correctamente.

Cuando sea necesario modificar `firestore.rules`, entregar siempre el archivo completo.

---

# 10. Validación funcional

Se realizó una validación integrada del MVP.

Flujo probado:

**Negocio → Categoría → Producto → Stock → Venta → Movimiento de stock → Gastos → Dashboard → Caja → Clientes**

También se probaron individualmente:

- Categorías.
- Productos.
- Stock.
- Movimientos de stock.
- Ventas.
- Historial de ventas.
- Clientes.
- Detalle de clientes.
- Gastos.
- Caja.
- Dashboard.
- Perfil.
- Reinicio de datos.
- Tema claro.
- Tema oscuro.

### Resultado

Los módulos trabajan correctamente entre sí en las pruebas realizadas.

No se detectaron errores funcionales pendientes conocidos en esta etapa.

---

# 11. Validación técnica

Antes de cerrar esta etapa se ejecutó:

```powershell
flutter analyze

```

Resultado:

**No issues found!**

También se revisó:

```powershell
git status

```

Resultado:

**Repositorio limpio después del commit.**

---

# 12. Git — estado actual

Commit de esta etapa:

```text
a2c5029 Finalize MVP redesign and validation

```

El commit incluye los cambios realizados durante la etapa de rediseño, integración, tema, preferencias, seguridad y validación.

También se realizó:

```powershell
git push origin main

```

El estado actual fue subido correctamente a la rama:

`main`

### Punto de control

Este commit representa una versión estable del MVP.

No se deben descartar ni restaurar estos cambios sin una razón concreta.

---

# 13. Archivos y servicios importantes

Entre los archivos modificados durante esta etapa se encuentran:

- `PROJECT_CONTEXT.md`
- `firestore.rules`
- `lib/main.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/customer_detail_screen.dart`
- `lib/screens/products_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/sales_history_screen.dart`
- `lib/screens/sales_screen.dart`
- `lib/screens/stock_screen.dart`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.yaml`
- `pubspec.lock`

Servicios agregados:

- `lib/services/app_preferences.dart`
- `lib/services/theme_controller.dart`

No eliminar los servicios sin comprobar antes sus referencias.

---

# 14. Estado actual del MVP

Actualmente BizzFlow cuenta con:

- Panel principal.
- Dashboard.
- Ventas.
- Historial de ventas.
- Productos.
- Stock.
- Historial de movimientos de stock.
- Categorías.
- Clientes.
- Detalle de clientes.
- Gastos.
- Caja.
- Perfil.
- Reinicio de datos.
- Firebase Authentication.
- Firestore.
- Reglas de seguridad por negocio.
- Tema claro.
- Tema oscuro.
- Preferencias de tema.
- Diseño responsive.
- Integración entre módulos.
- Validación funcional.
- Validación técnica.

### Estado general

**MVP estable y funcional.**

La aplicación está en condiciones de pasar a una etapa de prueba con un negocio real.

---

# 15. Próxima etapa

La prioridad inmediata ya no es agregar funcionalidades grandes.

El siguiente objetivo es:

## Prueba con un negocio real

La aplicación debe utilizarse en un escenario real para detectar:

- Pasos innecesarios.
- Campos que sobren.
- Campos que falten.
- Procesos incómodos.
- Problemas de navegación.
- Información difícil de encontrar.
- Necesidades reales del negocio.
- Problemas que no aparecen durante las pruebas técnicas.

La experiencia real debe utilizarse para decidir qué mejorar.

---

# 16. Mejoras futuras

Después de la prueba real se podrán evaluar:

- Mejoras de UX.
- Mejoras visuales puntuales.
- Estadísticas simples.
- Resúmenes.
- Vinculación de clientes con ventas.
- Mejoras de búsqueda y filtros.
- Funcionalidades solicitadas por negocios reales.

No agregar funcionalidades solamente por ampliar el proyecto.

Cada nueva función debe justificar su utilidad para el MVP.

---

# 17. Funcionalidades fuera del alcance actual

No agregar todavía salvo necesidad real:

- Pagos.
- Facturación electrónica.
- Proveedores avanzados.
- Empleados.
- Permisos avanzados.
- Reportes complejos.
- Gráficos avanzados.
- Notificaciones.
- IA.
- Gastos recurrentes.
- Archivos adjuntos.
- Automatizaciones complejas.
- Funcionalidades que no sean necesarias para validar el MVP.

---

# 18. Reglas de trabajo del usuario

El usuario trabaja principalmente con:

- Windows.
- PowerShell.
- Cursor.
- Flutter.
- Firebase.
- Git.

### Preferencia fundamental

El usuario NO quiere modificar código por partes.

Cuando haya un problema de código:

**Siempre entregar el archivo completo corregido para reemplazarlo.**

No pedirle que busque una línea concreta y cambie solamente una parte salvo que sea absolutamente necesario.

### Flujo de trabajo preferido

1. Preparar archivo completo.
2. Usuario reemplaza el archivo.
3. Ejecutar `flutter analyze`.
4. Corregir errores.
5. Probar en Chrome.
6. Confirmar funcionamiento.
7. Actualizar `PROJECT_CONTEXT.md`.
8. Ejecutar `git status`.
9. Revisar cambios.
10. Commit.
11. Push a GitHub.
12. Continuar con el siguiente objetivo.

### Regla importante

No avanzar al siguiente objetivo si:

```text
flutter analyze

```

presenta errores.

---

# 19. Regla para cambios futuros

Antes de modificar una pantalla o funcionalidad:

1. Leer este `PROJECT_CONTEXT.md`.
2. Revisar el código actual.
3. No asumir que una implementación anterior está incompleta sin comprobarla.
4. Mantener la arquitectura basada en `businessId`.
5. Mantener las reglas de seguridad.
6. No romper funcionalidades que ya fueron validadas.
7. Ejecutar `flutter analyze`.
8. Probar la funcionalidad.
9. Actualizar este documento si cambia el estado del proyecto.
10. Revisar Git antes de realizar commits.

---

# 20. Estado de cierre de esta etapa

La etapa de rediseño, integración y validación del MVP queda cerrada.

### Resultado final

**BizzFlow dispone actualmente de un MVP funcional, integrado, probado, con seguridad de Firestore, soporte de tema claro/oscuro, persistencia de datos, movimientos de stock, Caja integrada y un estado estable guardado en GitHub.**

### Último punto de control

```text
Commit: a2c5029
Rama: main
Estado: estable
flutter analyze: sin problemas
Git: limpio
Push: realizado

```

### Próximo objetivo

**Probar BizzFlow con un negocio real y utilizar esa experiencia para decidir las próximas mejoras.**