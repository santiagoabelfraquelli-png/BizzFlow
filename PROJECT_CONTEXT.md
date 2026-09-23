# BizzFlow — PROJECT_CONTEXT.md

> **Fuente de verdad del proyecto.**
>
> Antes de realizar cambios, leer este archivo completo y asumir que describe el estado actual del repositorio.

**Última actualización:** 2026-09-23

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
11. Perfil y configuración

Todos estos módulos están actualmente implementados.

La etapa actual se centra en:

- Consistencia visual
- Experiencia de usuario
- Tema claro/oscuro
- Robustez funcional
- Seguridad de Firestore
- Validación del MVP

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
- `stock_movements`

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

La pantalla puede recibir mejoras visuales adicionales posteriormente.

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

### Rediseño visual

La pantalla de Productos fue rediseñada visualmente manteniendo la lógica existente.

El rediseño incluye:

- Mejor jerarquía visual
- Tarjetas modernas
- Mejor organización de la información
- Espaciado consistente
- Iconografía renovada
- Diseño responsive
- Mejor experiencia en Chrome
- Conservación de las operaciones existentes

Los botones de acción utilizan el color principal del tema.

En modo oscuro, el color principal se mantiene dentro de la misma gama visual y se oscurece para adaptarse al fondo.

No se modificó la estructura de datos ni la lógica de Firebase asociada a los productos.

Estado:

**Funcional, probado y visualmente rediseñado.**

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

### Rediseño visual

La pantalla de Ventas fue rediseñada visualmente manteniendo la lógica funcional existente.

El rediseño incluye mejoras de:

- Jerarquía visual
- Carrito
- Presentación de productos
- Totales
- Botones de acción
- Espaciado
- Tarjetas
- Iconografía
- Responsive
- Experiencia de usuario

La transacción utilizada para registrar la venta y descontar stock se mantiene sin cambios funcionales.

Estado:

**Funcional, probado y visualmente rediseñado.**

Se comprobó mediante una venta real de prueba que:

- El total se calcula correctamente.
- La venta se registra.
- El stock se descuenta correctamente.
- Dashboard refleja la venta.

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

Estados actuales:

- `<= 0`: Sin stock
- `> 0` y `<= 5`: Stock bajo
- `> 5`: Stock disponible

### Rediseño visual

La pantalla de Stock fue rediseñada visualmente manteniendo toda la lógica existente.

El diseño incluye:

- Encabezado visual
- Resumen general del inventario
- Cantidad total de productos
- Cantidad de productos disponibles
- Cantidad de productos con stock bajo
- Cantidad de productos sin stock
- Tarjetas modernas para cada producto
- Indicadores visuales de estado
- Mejor presentación de cantidad y unidad
- Botón de agregar stock renovado
- Modal de agregar stock rediseñado
- Diseño responsive
- Adaptación a distintas cantidades de columnas en Chrome
- Mejor jerarquía visual
- Sombras y bordes redondeados
- Iconografía renovada

El rediseño no modifica:

- Firebase
- Firestore
- `businessId`
- Transacciones
- Estructura de productos
- Criterio de stock bajo
- Funcionamiento de agregar stock

### Regla de stock bajo

Actualmente se mantiene:

- `0 o menor`: sin stock
- `1 a 5`: stock bajo
- `más de 5`: disponible

Este criterio NO debe modificarse salvo solicitud explícita.

Estado:

**Funcional, probado y visualmente rediseñado.**

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

**Funcional y probado.**

Se comprobó:

- Creación
- Visualización
- Edición
- Eliminación

La pantalla puede recibir mejoras visuales adicionales posteriormente.

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

Se comprobó que los gastos aparecen correctamente en:

- Gastos
- Dashboard
- Caja

La pantalla puede recibir mejoras visuales adicionales posteriormente.

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

**Funcional, integrado y probado.**

Se comprobó:

- Apertura de Caja
- Carga de datos
- Creación de movimientos
- Actualización del saldo
- Visualización de movimientos
- Ingresos
- Egresos
- Integración con ventas
- Integración con gastos

También se comprobó mediante una prueba real que:

- Una venta de `$2000` aparece como ingreso.
- Un gasto de `$500` aparece como egreso.
- El saldo resultante es `$1500`.

La colección `cash_movements` cuenta con reglas de seguridad basadas en `businessId` y propietario del negocio.

No se requieren índices compuestos para las consultas actuales de Caja, ya que el filtrado por `businessId` se realiza directamente y el orden de los movimientos se procesa en la aplicación.

La pantalla puede recibir mejoras visuales adicionales posteriormente.

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

### Rediseño visual

El Dashboard fue rediseñado visualmente manteniendo la lógica y las consultas existentes.

El nuevo diseño incluye:

- Encabezado visual del Dashboard
- Tarjetas de métricas
- Iconos
- Colores diferenciados por tipo de información
- Tarjetas de stock
- Diseño responsive
- Bordes redondeados
- Sombras
- Animaciones y transiciones visuales
- Adaptación del número de columnas según el ancho disponible

Estado:

**Funcional, probado y visualmente rediseñado.**

Se comprobó mediante una prueba integrada que:

- Las ventas del día aparecen correctamente.
- La cantidad de ventas se actualiza.
- Los gastos del día aparecen correctamente.
- El resultado del día se calcula correctamente.
- El stock sin existencias se informa correctamente.
- El stock bajo se informa según el criterio actual.

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

### Rediseño visual

El `BusinessHomeScreen` fue rediseñado visualmente manteniendo la lógica de navegación y el `businessId`.

El nuevo diseño incluye:

- Encabezado de bienvenida
- Diseño basado en tarjetas
- Iconos para cada módulo
- Colores diferenciados por módulo
- Bordes redondeados
- Sombras
- Animaciones de entrada
- Efectos visuales al pasar el mouse
- Escalado y desplazamiento suave de tarjetas
- Diseño responsive mediante `LayoutBuilder`
- Mejor organización visual de los accesos

Los módulos y sus rutas de navegación se mantienen sin cambios funcionales.

### Caja

El acceso a Caja utiliza:

`CashScreen`

y recibe:

`businessId`

La navegación fue probada correctamente.

Estado:

**Funcional, probado y visualmente rediseñado.**

---

# 12. Perfil y configuración

La aplicación cuenta con una pantalla de perfil/configuración del negocio.

Entre sus funcionalidades se encuentra:

- Visualización de información del usuario/negocio.
- Acciones relacionadas con la configuración.
- Reinicio de datos del negocio.

### Reiniciar datos

La opción **Reiniciar datos** permite eliminar los registros pertenecientes al `businessId` actual de las siguientes colecciones:

- `sales`
- `expenses`
- `cash_movements`
- `products`
- `customers`
- `categories`
- `stock_movements`

El proceso utiliza consultas filtradas por:

`businessId`

y elimina los documentos mediante operaciones por lotes.

El proceso trabaja en lotes de hasta 450 documentos para evitar superar los límites de una operación batch.

### Seguridad

La eliminación se encuentra protegida mediante las reglas de Firestore y únicamente debe afectar documentos pertenecientes al negocio del usuario autenticado.

Se corrigió un problema de permisos relacionado con:

`stock_movements`

La regla correspondiente ahora permite:

- Crear
- Leer
- Eliminar

siempre que el documento pertenezca al negocio cuyo propietario coincide con el usuario autenticado.

### Estado

**Funcional y probado.**

Se verificó que la opción **Reiniciar datos** puede ejecutarse correctamente después de publicar las reglas actualizadas de Firestore.

---

# 13. Tema visual

BizzFlow cuenta actualmente con soporte visual para:

- Tema claro
- Tema oscuro

### Tema oscuro

Todas las pantallas principales fueron adaptadas para funcionar correctamente en modo oscuro.

El criterio visual utilizado es:

- Mantener la identidad visual existente.
- Evitar fondos o componentes con blancos incorrectos en modo oscuro.
- Mantener el color principal de la aplicación.
- Oscurecer el color principal cuando sea necesario para botones y acciones en modo oscuro, en lugar de cambiarlo por otro color completamente diferente.
- Mantener buena legibilidad de textos.
- Mantener contraste suficiente entre fondos, tarjetas y controles.

En Productos, por ejemplo, los botones de acción utilizan el color principal del tema y, en modo oscuro, una versión oscurecida del mismo color.

### Estado

**Tema claro y oscuro implementados y revisados en las pantallas actuales.**

No se debe modificar la identidad cromática sin solicitud explícita.

---

# 14. Reglas de Firestore

Las reglas actuales protegen:

- users
- businesses
- categories
- products
- sales
- customers
- expenses
- cash_movements
- stock_movements

Los módulos que almacenan datos del negocio verifican que:

1. El usuario esté autenticado.
2. El documento tenga `businessId`.
3. El negocio correspondiente pertenezca al usuario autenticado.

La regla fundamental es:

**Un usuario nunca debe poder leer, modificar, eliminar o crear datos asociados a otro negocio.**

### Stock movements

La colección:

`stock_movements`

permite:

- Crear
- Leer
- Eliminar

siempre que el documento pertenezca a un negocio cuyo `ownerId` coincida con el usuario autenticado.

Esto es necesario para que la función **Reiniciar datos** pueda eliminar correctamente los movimientos de stock del negocio.

### Publicación de reglas

Cuando se modifica `firestore.rules`, el archivo local no es suficiente.

Las reglas deben publicarse mediante:

```powershell
firebase deploy --only firestore:rules

```

No considerar una modificación de reglas como terminada hasta confirmar que fue publicada correctamente.

### Regla de trabajo

Cuando sea necesario modificar las reglas:

**Siempre entregar el archivo completo de reglas de Firestore y no un fragmento aislado.**

---

# 15. Estado actual del código

Actualmente:

- Los módulos principales están implementados.
- Caja está integrada al panel.
- Caja puede crear movimientos.
- Firestore permite guardar movimientos de Caja.
- El MVP fue probado mediante un flujo integrado.
- El Panel principal fue rediseñado y validado.
- El Dashboard fue rediseñado y validado.
- Ventas fue rediseñada visualmente.
- Productos fue rediseñada visualmente.
- Stock fue rediseñado visualmente.
- El tema oscuro está aplicado a las pantallas actuales.
- Los colores de acciones fueron adaptados para conservar la identidad visual en modo oscuro.
- La lógica de negocio existente se mantiene en los rediseños visuales.
- La opción Reiniciar datos funciona correctamente.
- Las reglas de Firestore fueron ajustadas para permitir el borrado seguro de `stock_movements`.
- No se detectaron errores funcionales durante las validaciones realizadas.

### Estado de rediseño visual

Actualmente cuentan con rediseño visual:

- `lib/screens/business_setup_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/sales_screen.dart`
- `lib/screens/products_screen.dart`
- `lib/screens/stock_screen.dart`

Las siguientes pantallas pueden recibir mejoras visuales adicionales si se considera necesario:

- `lib/screens/customers_screen.dart`
- `lib/screens/expenses_screen.dart`
- `lib/screens/cash_screen.dart`
- `lib/screens/categories_screen.dart`

Sin embargo, el soporte de **tema oscuro ya está implementado en las pantallas actuales** y no debe considerarse una tarea pendiente general.

### Archivos modificados durante la etapa actual de rediseño

- `lib/screens/business_setup_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/sales_screen.dart`
- `lib/screens/products_screen.dart`
- `lib/screens/stock_screen.dart`

También pueden existir modificaciones en:

- `lib/screens/profile_screen.dart`
- `firestore.rules`
- `PROJECT_CONTEXT.md`

según las correcciones realizadas posteriormente.

Los cambios visuales y funcionales deben conservarse y no deben descartarse antes del commit correspondiente.

No se debe asumir que una nueva funcionalidad está terminada hasta comprobar:

1. `flutter analyze`
2. Prueba en Chrome
3. Lectura correcta de Firestore
4. Escritura correcta de Firestore cuando corresponda
5. Seguridad mediante reglas cuando corresponda

---

# 16. Validación general realizada

Se realizó una prueba integrada del MVP utilizando datos de prueba.

Flujo probado:

**Negocio → Categoría → Producto → Stock → Venta → Gasto → Dashboard → Caja → Clientes**

### Prueba de ventas y stock

Se utilizó:

- Producto: Coca Cola
- Stock inicial: 5
- Precio unitario: `$1000`
- Cantidad vendida: 2

Resultado esperado y comprobado:

- Total de venta: `$2000`
- Stock restante: `3`

### Prueba de gastos

Se registró:

- Gasto de prueba: `$500`

Resultado:

- Gastos del día: `$500`
- Resultado del día: `$1500`

### Prueba de Caja

Resultado:

- Ingresos: `$2000`
- Egresos: `$500`
- Saldo: `$1500`

Los movimientos aparecen correctamente en Dashboard y Caja.

### Prueba de Clientes

Se comprobó:

- Crear cliente
- Visualizar cliente
- Editar cliente
- Eliminar cliente

### Prueba del rediseño visual

Se comprobó:

- Panel principal rediseñado
- Navegación desde el nuevo panel
- Dashboard rediseñado
- Ventas rediseñadas
- Productos rediseñados
- Stock rediseñado
- Visualización de métricas
- Visualización de stock
- Diseño responsive
- Animaciones y efectos visuales
- Conservación de los datos existentes
- Conservación de la lógica de Firebase y Firestore

### Validación de Stock

Después del rediseño de `stock_screen.dart` se ejecutó:

`flutter analyze`

Resultado:

**Sin problemas.**

Se verificó que el rediseño conserva:

- Consulta de productos mediante `businessId`
- Orden alfabético
- Estado del stock
- Agregado de stock
- Transacción Firestore
- Validación de pertenencia al negocio
- Mensajes de éxito y error

### Validación de Reiniciar datos

Se verificó la funcionalidad de:

**Mi Perfil → Reiniciar datos**

El proceso inicialmente presentó un error de permisos debido a que `stock_movements` no permitía eliminación.

Se corrigieron las reglas de Firestore para permitir el borrado seguro de dichos documentos.

Después de publicar las reglas actualizadas:

**Reiniciar datos funciona correctamente.**

### Resultado de la validación

**El MVP actual funciona correctamente en las pruebas realizadas y cuenta con un rediseño visual validado para Panel principal, Dashboard, Ventas, Productos y Stock, además de soporte de tema oscuro y una función de reinicio de datos correctamente protegida.**

---

# 17. Preferencias de trabajo del usuario

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
11. Continuar con el siguiente objetivo.

### Regla importante

No avanzar al siguiente objetivo si `flutter analyze` tiene errores.

---

# 18. Git

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

# 19. Próximos pasos

## Paso 1 — Guardar el estado actual

El estado funcional y visual actual está validado.

Actualmente cuentan con:

- Panel principal rediseñado.
- Dashboard rediseñado.
- Ventas rediseñadas.
- Productos rediseñados.
- Stock rediseñado.
- Tema oscuro aplicado.
- Tema claro conservado.
- Reinicio de datos funcional.
- Reglas de Firestore ajustadas para el reinicio.
- MVP funcional.

Pendiente inmediato:

- Reemplazar `PROJECT_CONTEXT.md` con esta versión actualizada.
- Ejecutar `git status`.
- Confirmar que los cambios correspondan únicamente a lo esperado.
- No realizar commit ni push hasta revisar el estado.

---

## Paso 2 — Revisar funcionalidad antes de agregar nuevas características

La prioridad siguiente no es modificar nuevamente el tema oscuro.

Se debe revisar el funcionamiento completo de los módulos existentes y detectar posibles problemas de lógica o integración.

Especial atención a:

1. Ventas + Stock
2. Ventas + Caja
3. Gastos + Caja
4. Dashboard
5. Clientes
6. Categorías
7. Productos
8. Reiniciar datos

El objetivo es garantizar que los módulos trabajen correctamente entre sí.

---

## Paso 3 — Mejoras visuales restantes

Si después de revisar la funcionalidad se considera necesario, continuar con mejoras visuales de:

1. Clientes
2. Gastos
3. Caja
4. Categorías
5. Pantallas secundarias

No modificar una pantalla únicamente por modificarla.

Cada cambio visual debe aportar:

- Mejor legibilidad
- Mejor organización
- Mejor experiencia de usuario
- Consistencia con el resto de BizzFlow

---

## Paso 4 — Prueba con negocio real

Probar BizzFlow con un negocio pequeño real para detectar:

- Flujos innecesarios
- Campos que sobren
- Campos que falten
- Procesos tediosos
- Problemas de usabilidad
- Necesidades reales del negocio

La prueba con usuarios reales debe utilizarse para decidir qué funcionalidades agregar posteriormente.

---

## Paso 5 — Resumen / estadísticas

Evaluar posteriormente si hace falta implementar un módulo adicional de resumen o estadísticas.

No agregar gráficos o reportes complejos sin necesidad.

---

# 20. Alcance actual

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

**tener una aplicación pequeña, funcional, visualmente clara y utilizable rápidamente para probarla con negocios reales.**

La etapa actual se centra principalmente en:

**funcionalidad + consistencia visual + UX + seguridad + validación del MVP.**

No comenzar nuevas funcionalidades grandes hasta comprobar que los módulos existentes funcionan correctamente de punta a punta.

