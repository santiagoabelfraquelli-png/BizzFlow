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

El flujo previsto del MVP es:

1. Crear/iniciar sesión
2. Configurar negocio
3. Categorías
4. Productos
5. Stock
6. Ventas
7. Clientes
8. Gastos
9. Caja
10. Resumen / estadísticas básicas

Todavía faltan Caja y Resumen.

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

**Implementado.**

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

El código de `expenses_screen.dart` quedó sin errores después de corregir problemas de copia/pegado.

### Importante

Todavía falta agregar la regla de Firestore para:

`expenses`

No continuar con funcionalidades posteriores hasta conectar y probar correctamente este módulo.

---

# 9. Panel principal

Archivo:

`lib/screens/business_setup_screen.dart`

Este archivo contiene:

- Configuración inicial del negocio
- Creación del documento `businesses`
- Asociación del negocio al usuario
- `BusinessHomeScreen`
- Panel principal
- Accesos a los módulos

El panel debe contener:

- Ventas
- Stock
- Categorías
- Productos
- Clientes
- Gastos

Actualmente se está intentando agregar correctamente el acceso a `ExpensesScreen`.

---

# 10. Problema actual

Se intentó actualizar `business_setup_screen.dart` para agregar el botón de Gastos.

El usuario tuvo errores de compilación porque al copiar código desde ChatGPT se introdujeron caracteres/formato extra dentro del archivo.

Los errores aparecieron en varias líneas y provocaron una cascada de errores como:

- `missing_identifier`
- `expected_token`
- `undefined_method`
- `dead_code`
- `ModuleItem isn't defined`

Esto NO debe interpretarse automáticamente como múltiples problemas de lógica.

El patrón indica que el contenido del archivo quedó corrupto o recibió caracteres adicionales durante la copia.

### Preferencia importante del usuario

El usuario NO quiere modificar código por partes.

Cuando haya un problema:

**SIEMPRE entregar el archivo completo corregido para reemplazarlo.**

No pedirle que busque una línea concreta y cambie solamente una parte salvo que sea absolutamente necesario.

---

# 11. Preferencias de trabajo del usuario

El usuario trabaja con:

- Windows
- PowerShell
- Cursor

No asumir que utiliza VS Code.

Flujo preferido:

1. Preparar archivo completo.
2. Usuario reemplaza el archivo.
3. Ejecutar `flutter analyze`.
4. Corregir cualquier error.
5. Probar en Chrome.
6. Confirmar funcionamiento.
7. Actualizar `PROJECT_CONTEXT.md`.
8. Commit de Git.
9. Continuar con el siguiente módulo.

### Importante

No avanzar al siguiente módulo si `flutter analyze` tiene errores.

---

# 12. Reglas de Firestore actuales

Las reglas actuales tienen autorización para:

- users
- businesses
- categories
- products
- sales
- customers

Todavía falta agregar `expenses`.

La regla esperada para gastos es:

```rules
match /expenses/{expenseId} {
  allow create: if request.auth != null
                && request.resource.data.businessId != null
                && get(
                     /databases/$(database)/documents/businesses/$(request.resource.data.businessId)
                   ).data.ownerId == request.auth.uid;

  allow read, update, delete: if request.auth != null
                              && resource.data.businessId != null
                              && get(
                                   /databases/$(database)/documents/businesses/$(resource.data.businessId)
                                 ).data.ownerId == request.auth.uid;
}

```

Cuando se agregue, preferir entregar el archivo completo de reglas de Firestore y no un fragmento aislado.

---

# 13. Próximos pasos

Orden recomendado:

### Paso 1

Dejar `business_setup_screen.dart` completamente limpio.

### Paso 2

Ejecutar:

`flutter analyze`

Debe quedar sin errores.

### Paso 3

Probar en Chrome:

- Abrir panel
- Ver botón Gastos
- Entrar a Gastos

### Paso 4

Agregar regla Firestore para `expenses`.

### Paso 5

Probar:

- Crear gasto
- Ver gasto
- Editar gasto
- Eliminar gasto
- Verificar total
- Verificar `businessId`

### Paso 6

Continuar con:

**Caja**

### Paso 7

Implementar:

**Resumen / estadísticas básicas**

### Paso 8

Prueba completa del MVP.

### Paso 9

Actualizar este archivo.

### Paso 10

Commit y push a GitHub.

---

# 14. Alcance actual

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