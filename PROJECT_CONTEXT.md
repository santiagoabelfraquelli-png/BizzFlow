```markdown
# BizzFlow — PROJECT_CONTEXT.md

> **Fuente de verdad del proyecto.**
>
> Antes de realizar cambios, leer este archivo completo y asumir que describe el estado actual del repositorio.

**Última actualización:** 2026-09-22

---

## 1. Objetivo del proyecto

BizzFlow es una aplicación de gestión para pequeños negocios.

El objetivo actual es crear un MVP funcional que pueda probarse rápidamente con negocios reales antes de desarrollar funcionalidades más avanzadas.

El proyecto está desarrollado con:

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Git / GitHub
* Cursor como editor

El usuario es principiante/intermedio en programación y prefiere soluciones completas y concretas.

---

## 2. Proyecto local

Ruta actual:

`C:\Users\barbitaaa\PYTHON\BizzFlow`

Nombre del paquete:

`bizzflow`

---

## 3. Arquitectura

La aplicación utiliza una arquitectura multi-negocio.

Cada usuario puede estar asociado a un negocio mediante:

`users/{userId}`

con el campo:

`businessId`

Los datos de cada módulo utilizan `businessId` para separar la información de distintos negocios.

### Regla fundamental

Un negocio nunca debe poder acceder a los datos de otro negocio.

---

## 4. Flujo principal actual

El flujo actual del MVP es:

1. Crear/iniciar sesión
2. Configurar negocio
3. Dashboard
4. Ventas
5. Caja
6. Stock
7. Categorías
8. Productos
9. Clientes
10. Gastos

Todos estos módulos están actualmente implementados, integrados y probados.

El siguiente paso no es agregar otro módulo grande inmediatamente, sino mantener una versión estable del MVP y evaluar posteriormente mejoras o una prueba con un negocio real.

---

# 5. Firebase Authentication

Firebase Authentication está configurado para:

* Registro
* Inicio de sesión
* Verificación de email
* Recuperación de contraseña

La sesión de Firebase se mantiene entre aperturas de la aplicación.

No guardar contraseñas en texto plano en Firestore.

---

# 6. Firestore

Colecciones utilizadas actualmente:

* `users`
* `businesses`
* `categories`
* `products`
* `sales`
* `customers`
* `expenses`
* `cash_movements`

Todas las colecciones de datos del negocio utilizan `businessId`.

---

# 7. Módulos terminados

## Categorías

Archivo:

`lib/screens/categories_screen.dart`

Funcionalidades:

* Listar categorías
* Crear categorías
* Eliminar categorías
* Orden alfabético
* Filtrado por `businessId`

Campos:

* `businessId`
* `name`
* `active`
* `createdAt`

Estado:

**Funcional y probado.**

---

## Productos

Archivo:

`lib/screens/products_screen.dart`

Funcionalidades:

* Crear productos
* Listar productos
* Eliminar productos
* Seleccionar categoría
* Precio
* Stock inicial
* Unidad
* Filtrado por `businessId`

Unidades disponibles:

* unidad
* kg
* g
* litro
* ml

Campos:

* `businessId`
* `name`
* `categoryId`
* `categoryName`
* `price`
* `stock`
* `unit`
* `active`
* `createdAt`

Estado:

**Funcional y probado.**

---

## Ventas

Archivo:

`lib/screens/sales_screen.dart`

Funcionalidades:

* Listar productos
* Agregar productos al carrito
* Incrementar cantidades
* Eliminar productos del carrito
* Calcular total
* Confirmar venta
* Descontar stock
* Crear registro de venta

La venta utiliza una transacción de Firestore para actualizar el stock y registrar la venta de forma atómica.

Campos principales de una venta:

* `businessId`
* `items`
* `total`
* `createdAt`

Cada item contiene:

* `productId`
* `productName`
* `quantity`
* `unit`
* `unitPrice`
* `subtotal`

Estado:

**Funcional y probado.**

Se comprobó mediante una venta real de prueba que:

* El total se calcula correctamente.
* La venta se registra.
* El stock se descuenta correctamente.
* Dashboard refleja la venta.

---

## Stock

Archivo:

`lib/screens/stock_screen.dart`

Funcionalidades:

* Ver stock de productos
* Mostrar categoría
* Mostrar unidad
* Estado del stock
* Agregar stock
* Actualización mediante transacción Firestore

Estados visuales actuales:

* `<= 0`: Sin stock
* `<= 5`: Stock bajo
* `> 5`: Stock disponible

Estado:

**Funcional y probado.**

### Nota

Actualmente el Dashboard considera como stock bajo los productos con stock `<= 5`.

Este criterio podrá revisarse posteriormente. No modificarlo hasta realizar una decisión específica sobre el comportamiento deseado.

---

## Clientes

Archivo:

`lib/screens/customers_screen.dart`

Funcionalidades:

* Crear cliente
* Listar clientes
* Editar cliente
* Eliminar cliente

Datos:

* Nombre obligatorio
* Teléfono opcional
* Email opcional
* `businessId`
* `createdAt`

Actualmente los clientes todavía no están vinculados con las ventas.

Esto es intencional para mantener el MVP simple.

Estado:

**Funcional y probado.**

Se comprobó:

* Creación
* Visualización
* Edición
* Eliminación

---

# 8. Gastos

Archivo:

`lib/screens/expenses_screen.dart`

El módulo está implementado.

Funcionalidades:

* Crear gasto
* Editar gasto
* Eliminar gasto
* Listar gastos
* Mostrar total de gastos
* Ordenar por fecha
* Categorías de gastos
* Fecha del gasto
* Filtrado por `businessId`

Categorías:

* Insumos
* Alquiler
* Servicios
* Transporte
* Sueldos
* Mantenimiento
* Otros

Campos:

* `businessId`
* `description`
* `amount`
* `category`
* `date`
* `createdAt`

Estado:

**Funcional y probado.**

La regla de Firestore para `expenses` está implementada y publicada.

Se comprobó que los gastos aparecen correctamente en:

* Gastos
* Dashboard
* Caja

---

# 9. Caja

Archivo:

`lib/screens/cash_screen.dart`

La Caja utiliza la colección:

`cash_movements`

Cada movimiento manual contiene:

* `businessId`
* `type`
* `amount`
* `description`
* `date`
* `createdAt`
* `source`

Tipos posibles:

* `income`
* `expense`

Fuentes:

* `manual`
* `sale`
* `expense`

### Funcionamiento

La Caja obtiene:

* Ventas existentes como ingresos
* Gastos existentes como egresos
* Movimientos manuales como ingresos o egresos

El cálculo es:

**Saldo = ventas + ingresos manuales - gastos - egresos manuales**

La pantalla muestra:

* Saldo actual
* Ingresos
* Egresos
* Lista de movimientos

Permite crear movimientos manuales mediante un botón flotante.

### Movimientos manuales

Se pueden crear:

* Ingresos
* Egresos

Cada movimiento permite indicar:

* Tipo
* Descripción
* Monto
* Fecha

### Estado

**Funcional, integrado y probado.**

Se comprobó:

* Apertura de Caja
* Carga de datos
* Creación de movimientos
* Actualización del saldo
* Visualización de movimientos
* Ingresos
* Egresos
* Integración con ventas
* Integración con gastos

También se comprobó mediante una prueba real que:

* Una venta de `$2000` aparece como ingreso.
* Un gasto de `$500` aparece como egreso.
* El saldo resultante es `$1500`.

La colección `cash_movements` cuenta con reglas de seguridad basadas en `businessId` y propietario del negocio.

No se requieren índices compuestos para las consultas actuales de Caja, ya que el filtrado por `businessId` se realiza directamente y el orden de los movimientos se procesa en la aplicación.

---

# 10. Dashboard

Archivo:

`lib/screens/dashboard_screen.dart`

El Dashboard muestra un resumen básico del negocio.

Datos actuales:

* Ventas de hoy
* Cantidad de ventas
* Gastos de hoy
* Resultado del día
* Productos sin stock
* Productos con stock bajo

Las ventas se consultan utilizando:

* `businessId`
* `createdAt`

Los gastos se consultan utilizando:

* `businessId`
* `date`

### Índices Firestore

Se crearon los siguientes índices compuestos:

#### Sales

* `businessId` Ascending
* `createdAt` Ascending

#### Expenses

* `businessId` Ascending
* `date` Ascending

Estado:

**Funcional y probado.**

Se comprobó mediante una prueba integrada que:

* Las ventas del día aparecen correctamente.
* La cantidad de ventas se actualiza.
* Los gastos del día aparecen correctamente.
* El resultado del día se calcula correctamente.
* El stock sin existencias se informa correctamente.
* El stock bajo se informa según el criterio actual.

---

# 11. Panel principal

Archivo:

`lib/screens/business_setup_screen.dart`

Este archivo contiene:

* Configuración inicial del negocio
* Creación del documento `businesses`
* Asociación del negocio al usuario
* `BusinessHomeScreen`
* Panel principal
* Accesos a los módulos

Actualmente el panel contiene:

* Dashboard
* Ventas
* Caja
* Stock
* Categorías
* Productos
* Clientes
* Gastos

Cada módulo recibe el `businessId` correspondiente.

### Caja

El acceso a Caja utiliza:

`CashScreen`

y recibe:

`businessId`

La navegación fue probada correctamente.

Estado:

**Funcional y probado.**

---

# 12. Reglas de Firestore

Las reglas actuales protegen:

* users
* businesses
* categories
* products
* sales
* customers
* expenses
* cash_movements

Los módulos que almacenan datos del negocio verifican que:

1. El usuario esté autenticado.
2. El documento tenga `businessId`.
3. El negocio correspondiente pertenezca al usuario autenticado.

La regla fundamental es:

**Un usuario nunca debe poder leer, modificar, eliminar o crear datos asociados a otro negocio.**

Las reglas de `cash_movements` fueron agregadas y publicadas correctamente.

Cuando sea necesario modificar las reglas:

**Siempre entregar el archivo completo de reglas de Firestore y no un fragmento aislado.**

---

# 13. Estado actual del código

Actualmente:

* `flutter analyze` está sin problemas.
* Caja está integrada al panel.
* Caja puede crear movimientos.
* Firestore permite guardar movimientos de Caja.
* Los módulos principales están funcionales.
* El MVP completo fue probado mediante un flujo integrado.
* No se detectaron errores funcionales durante la validación actual.

No hay que asumir que una nueva funcionalidad está terminada hasta comprobar:

1. `flutter analyze`
2. Prueba en Chrome
3. Lectura correcta de Firestore
4. Escritura correcta de Firestore cuando corresponda
5. Seguridad mediante reglas cuando corresponda

---

# 14. Validación general realizada

Se realizó una prueba integrada del MVP utilizando datos de prueba.

Flujo probado:

**Negocio → Categoría → Producto → Stock → Venta → Gasto → Dashboard → Caja → Clientes**

### Prueba de ventas y stock

Se utilizó:

* Producto: Coca Cola
* Stock inicial: 5
* Precio unitario: `$1000`
* Cantidad vendida: 2

Resultado esperado y comprobado:

* Total de venta: `$2000`
* Stock restante: `3`

### Prueba de gastos

Se registró:

* Gasto de prueba: `$500`

Resultado:

* Gastos del día: `$500`
* Resultado del día: `$1500`

### Prueba de Caja

Resultado:

* Ingresos: `$2000`
* Egresos: `$500`
* Saldo: `$1500`

Los movimientos aparecen correctamente en Dashboard y Caja.

### Prueba de Clientes

Se comprobó:

* Crear cliente
* Visualizar cliente
* Editar cliente
* Eliminar cliente

### Resultado de la validación

**El MVP actual funciona correctamente en la prueba realizada.**

---

# 15. Preferencias de trabajo del usuario

El usuario trabaja con:

* Windows
* PowerShell
* Cursor

### Preferencia fundamental

El usuario NO quiere modificar código por partes.

Cuando haya un problema:

**SIEMPRE entregar el archivo completo corregido para reemplazarlo.**

No pedirle que busque una línea concreta y cambie solamente una parte salvo que sea absolutamente necesario.

### Flujo de trabajo preferido

1. Preparar archivo completo.
2. Usuario reemplaza el archivo.
3. Ejecutar `flutter analyze`.
4. Corregir cualquier error.
5. Probar en Chrome.
6. Confirmar funcionamiento.
7. Actualizar `PROJECT_CONTEXT.md`.
8. Revisar `git status`.
9. Commit.
10. Push a GitHub.
11. Continuar con el siguiente objetivo.

### Regla importante

No avanzar al siguiente objetivo si `flutter analyze` tiene errores.

---

# 16. Git

El repositorio utiliza:

* Git
* GitHub
* Rama principal: `main`

Antes de realizar un commit:

```powershell
git status
```

Revisar que solamente estén presentes los cambios esperados.

Después:

```powershell
git add .
git commit -m "Mensaje descriptivo"
git push
```

No realizar commits con cambios desconocidos o no relacionados.

---

# 17. Próximos pasos

## Paso 1 — Guardar el estado actual

La Caja ya está implementada, integrada y probada.

La validación general del MVP también fue realizada.

Pendiente inmediato:

- Ejecutar `flutter analyze`
- Revisar `git status`
- Confirmar los archivos modificados
- Crear commit
- Push a GitHub

---

## Paso 2 — Evaluar ajustes del MVP

Después de dejar esta versión guardada, evaluar únicamente mejoras que aporten valor real.

Un posible ajuste identificado durante las pruebas es revisar el criterio de:

**Stock bajo**

Actualmente:

- `0`: sin stock
- `1–5`: stock bajo
- `>5`: stock disponible

No modificarlo hasta decidir el comportamiento definitivo.

---

## Paso 3 — Prueba con negocio real

Probar BizzFlow con un negocio pequeño real para detectar:

- Flujos innecesarios
- Campos que sobren
- Campos que falten
- Procesos tediosos
- Problemas de usabilidad
- Necesidades reales del negocio

---

## Paso 4 — Resumen / estadísticas

Evaluar posteriormente si hace falta implementar un módulo adicional de resumen o estadísticas.

No agregar gráficos o reportes complejos sin necesidad.

---

# 18. Alcance actual

No agregar todavía:

- pagos
- facturación electrónica
- proveedores avanzados
- empleados
- permisos avanzados
- reportes complejos
- gráficos avanzados
- notificaciones
- IA
- gastos recurrentes
- archivos adjuntos
- funcionalidades que no sean necesarias para validar el MVP

La prioridad actual es:

**tener una aplicación pequeña, funcional y utilizable rápidamente para probarla con negocios reales.**

```

```

