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

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Git / GitHub
- Cursor como editor

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

El módulo de Caja ya está implementado e integrado en el panel principal.

El siguiente módulo grande pendiente es:

**Resumen / estadísticas básicas**, si se considera necesario después de validar el MVP actual.

---

# 5. Firebase Authentication

Firebase Authentication está configurado para:

- Registro
- Inicio de sesión
- Verificación de email
- Recuperación de contraseña

La sesión de Firebase se mantiene entre aperturas de la aplicación.

No guardar contraseñas en texto plano en Firestore.

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

Todas las colecciones de datos del negocio utilizan `businessId`.

---

# 7. Módulos terminados

## Categorías

Archivo:

`lib/screens/categories_screen.dart`

Funcionalidades:

- Listar categorías
- Crear categorías
- Eliminar categorías
- Orden alfabético
- Filtrado por `businessId`

Campos:

- `businessId`
- `name`
- `active`
- `createdAt`

Estado:

**Funcional y probado.**

---

## Productos

Archivo:

`lib/screens/products_screen.dart`

Funcionalidades:

- Crear productos
- Listar productos
- Eliminar productos
- Seleccionar categoría
- Precio
- Stock inicial
- Unidad
- Filtrado por `businessId`

Unidades disponibles:

- unidad
- kg
- g
- litro
- ml

Campos:

- `businessId`
- `name`
- `categoryId`
- `categoryName`
- `price`
- `stock`
- `unit`
- `active`
- `createdAt`

Estado:

**Funcional y probado.**

---

## Ventas

Archivo:

`lib/screens/sales_screen.dart`

Funcionalidades:

- Listar productos
- Agregar productos al carrito
- Incrementar cantidades
- Eliminar productos del carrito
- Calcular total
- Confirmar venta
- Descontar stock
- Crear registro de venta

La venta utiliza una transacción de Firestore para actualizar el stock y registrar la venta de forma atómica.

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

Estado:

**Funcional y probado.**

El usuario confirmó que el stock se descuenta correctamente al realizar una venta.

---

## Stock

Archivo:

`lib/screens/stock_screen.dart`

Funcionalidades:

- Ver stock de productos
- Mostrar categoría
- Mostrar unidad
- Estado del stock
- Agregar stock
- Actualización mediante transacción Firestore

Estados visuales:

- `<= 0`: Sin stock
- `<= 5`: Stock bajo
- `> 5`: Stock disponible

Estado:

**Funcional y probado.**

---

## Clientes

Archivo:

`lib/screens/customers_screen.dart`

Funcionalidades:

- Crear cliente
- Listar clientes
- Editar cliente
- Eliminar cliente

Datos:

- Nombre obligatorio
- Teléfono opcional
- Email opcional
- `businessId`
- `createdAt`

Actualmente los clientes todavía no están vinculados con las ventas.

Esto es intencional para mantener el MVP simple.

Estado:

**Implementado y funcional.**

---

# 8. Gastos

Archivo:

`lib/screens/expenses_screen.dart`

El módulo está implementado.

Funcionalidades:

- Crear gasto
- Editar gasto
- Eliminar gasto
- Listar gastos
- Mostrar total de gastos
- Ordenar por fecha
- Categorías de gastos
- Fecha del gasto
- Filtrado por `businessId`

Categorías:

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

Estado:

**Funcional y probado.**

La regla de Firestore para `expenses` está implementada y publicada.

---

# 9. Caja

Archivo:

`lib/screens/cash_screen.dart`

La Caja utiliza la colección:

`cash_movements`

Cada movimiento manual contiene:

- `businessId`
- `type`
- `amount`
- `description`
- `date`
- `createdAt`
- `source`

Tipos posibles:

- `income`
- `expense`

Fuentes:

- `manual`
- `sale`
- `expense`

### Funcionamiento

La Caja obtiene:

- Ventas existentes como ingresos
- Gastos existentes como egresos
- Movimientos manuales como ingresos o egresos

El cálculo es:

**Saldo = ventas + ingresos manuales - gastos - egresos manuales**

La pantalla muestra:

- Saldo actual
- Ingresos
- Egresos
- Lista de movimientos

Permite crear movimientos manuales mediante un botón flotante.

### Movimientos manuales

Se pueden crear:

- Ingresos
- Egresos

Cada movimiento permite indicar:

- Tipo
- Descripción
- Monto
- Fecha

### Estado

**Funcional y probado.**

Se comprobó:

- Apertura de Caja
- Carga de datos
- Creación de movimientos
- Actualización del saldo
- Visualización de movimientos
- Ingresos
- Egresos

La colección `cash_movements` cuenta con reglas de seguridad basadas en `businessId` y propietario del negocio.

No se requieren índices compuestos para las consultas actuales de Caja, ya que el filtrado por `businessId` se realiza directamente y el orden de los movimientos se procesa en la aplicación.

---

# 10. Dashboard

Archivo:

`lib/screens/dashboard_screen.dart`

El Dashboard muestra un resumen básico del negocio.

Datos actuales:

- Ventas de hoy
- Cantidad de ventas
- Gastos de hoy
- Resultado del día
- Productos sin stock
- Productos con stock bajo

Las ventas se consultan utilizando:

- `businessId`
- `createdAt`

Los gastos se consultan utilizando:

- `businessId`
- `date`

### Índices Firestore

Se crearon los siguientes índices compuestos:

#### Sales

- `businessId` Ascending
- `createdAt` Ascending

#### Expenses

- `businessId` Ascending
- `date` Ascending

Estado:

**Funcional y probado.**

---

# 11. Panel principal

Archivo:

`lib/screens/business_setup_screen.dart`

Este archivo contiene:

- Configuración inicial del negocio
- Creación del documento `businesses`
- Asociación del negocio al usuario
- `BusinessHomeScreen`
- Panel principal
- Accesos a los módulos

Actualmente el panel contiene:

- Dashboard
- Ventas
- Caja
- Stock
- Categorías
- Productos
- Clientes
- Gastos

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

- users
- businesses
- categories
- products
- sales
- customers
- expenses
- cash_movements

Los módulos que almacenan datos del negocio verifican que:

1. El usuario esté autenticado.
2. El documento tenga `businessId`.
3. El negocio correspondiente pertenezca al usuario autenticado.

La regla fundamental es:

**Un usuario nunca debe poder leer, modificar, eliminar o crear datos asociados a otro negocio.**

Cuando sea necesario modificar las reglas:

**Siempre entregar el archivo completo de reglas de Firestore y no un fragmento aislado.**

---

# 13. Estado actual del código

Actualmente:

- `flutter analyze` está sin problemas.
- Caja está integrada al panel.
- Caja puede crear movimientos.
- Firestore permite guardar movimientos de Caja.
- Los módulos principales están funcionales.

No hay que asumir que una nueva funcionalidad está terminada hasta comprobar:

1. `flutter analyze`
2. Prueba en Chrome
3. Lectura correcta de Firestore
4. Escritura correcta de Firestore cuando corresponda
5. Seguridad mediante reglas cuando corresponda

---

# 14. Preferencias de trabajo del usuario

El usuario trabaja con:

- Windows
- PowerShell
- Cursor

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
11. Continuar con el siguiente módulo.

### Regla importante

No avanzar al siguiente módulo si `flutter analyze` tiene errores.

---

# 15. Git

El repositorio utiliza:

- Git
- GitHub
- Rama principal: `main`

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

# 16. Próximos pasos

## Paso 1 — Cerrar Caja

Ya está implementada, integrada y probada.

Pendiente:

- Revisar `git status`
- Agregar cambios al commit
- Commit
- Push

---

## Paso 2 — Validación general

Realizar una prueba completa del MVP:

- Registro
- Inicio de sesión
- Configuración del negocio
- Dashboard
- Categorías
- Productos
- Stock
- Ventas
- Clientes
- Gastos
- Caja

Verificar especialmente que los datos pertenezcan al `businessId` correcto.

---

## Paso 3 — Resumen / estadísticas

Después de validar el MVP actual, evaluar si hace falta implementar un módulo de resumen/estadísticas adicionales.

No agregar gráficos o reportes complejos sin necesidad.

---

## Paso 4 — Prueba completa con negocio real

Probar BizzFlow con un negocio pequeño real para detectar:

- Flujos innecesarios
- Campos que sobren
- Campos que falten
- Procesos tediosos
- Problemas de usabilidad
- Necesidades reales del negocio

---

# 17. Alcance actual

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

Con esto el contexto queda alineado con **el estado real de hoy**: Caja ya no aparece como pendiente, está integrada y las reglas de `cash_movements` están contempladas.

Después de reemplazarlo, **no hagas todavía el commit**. Ejecutá:

```powershell
git status

```

y pasame el resultado. Así comprobamos exactamente qué archivos van a entrar en el commit.