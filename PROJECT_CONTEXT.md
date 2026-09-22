# BizzFlow — PROJECT CONTEXT

## 1. Descripción

BizzFlow es una plataforma multiplataforma para pequeños negocios.

El objetivo es permitir que distintos tipos de negocios puedan administrar sus operaciones desde una misma aplicación configurable.

Plataformas objetivo:

- Android
- iOS
- Web en una etapa posterior

## 2. Negocios objetivo iniciales

La primera versión estará orientada principalmente a:

- Restaurantes
- Panaderías
- Rotiserías
- Cafeterías

La arquitectura debe permitir agregar posteriormente otros tipos de negocios, por ejemplo:

- Barberías
- Peluquerías
- Centros de estética
- Técnicos
- Profesionales independientes
- Otros pequeños comercios



## 3. Objetivo del MVP

El MVP debe permitir que un propietario:

1. Cree una cuenta.
2. Cree/configure su negocio.
3. Agregue categorías.
4. Agregue productos.
5. Registre ventas.
6. Controle stock.
7. Administre clientes.
8. Registre gastos.
9. Consulte el estado básico de su caja.
10. Consulte estadísticas básicas.



## 4. Funciones futuras

Estas funciones NO forman parte del primer MVP, pero la arquitectura debe permitir incorporarlas posteriormente:

- Pedidos online.
- Delivery.
- Gestión de empleados.
- Múltiples sucursales.
- Reportes avanzados.
- Integración con WhatsApp.
- Pagos.
- Suscripciones.
- Asistente de IA.
- Automatizaciones.
- Notificaciones.
- Funciones específicas según el tipo de negocio.



## 5. Stack tecnológico

Frontend:

- Flutter
- Dart

Backend:

- Firebase
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Cloud Functions cuando sean necesarias

Control de versiones:

- Git
- GitHub

IDE principal:

- Cursor



## 6. Arquitectura

La aplicación debe diseñarse como un sistema multi-negocio (multi-tenant).

Los datos de un negocio nunca deben ser accesibles por otro negocio.

Las entidades principales estarán asociadas a un `businessId`.

Entidades iniciales previstas:

- users
- businesses
- categories
- products
- customers
- sales
- expenses



## 7. Principios de desarrollo

1. Mantener la arquitectura simple.
2. Evitar sobreingeniería.
3. No crear funcionalidades que no formen parte del MVP sin autorización.
4. Reutilizar componentes.
5. Mantener separación clara entre UI, modelos, servicios y lógica.
6. Priorizar seguridad de los datos.
7. Evitar duplicación de código.
8. Validar los cambios importantes antes de continuar.
9. No modificar archivos sin comprender su propósito.
10. Mantener el código preparado para futuras funcionalidades sin implementarlas prematuramente.



## 8. IA

La IA será incorporada después de que las funciones principales funcionen correctamente.

El asistente podrá eventualmente:

- Consultar datos del negocio.
- Responder preguntas sobre ventas.
- Analizar productos.
- Ayudar con stock.
- Generar textos comerciales.
- Automatizar tareas.

La IA nunca debe tener acceso indiscriminado a los datos de otros negocios.

## 9. Monetización futura

El modelo comercial previsto podrá incluir:

- Plan gratuito.
- Suscripción mensual.
- Funciones premium.
- Funciones de IA.
- Módulos adicionales.
- Múltiples sucursales.
- Personalización.
- Servicios de implementación.

La monetización no forma parte del primer MVP.

## 10. Estado actual

Proyecto Flutter recién creado.

Git configurado.

Repositorio privado de GitHub configurado.

Firebase todavía no está integrado.

La aplicación todavía utiliza la pantalla inicial generada por Flutter.

## 11. Regla importante para Cursor

Antes de realizar cambios importantes:

1. Leer este archivo.
2. Revisar la estructura actual del proyecto.
3. Explicar brevemente qué se va a modificar.
4. Evitar cambios fuera del alcance solicitado.
5. No eliminar funcionalidades existentes sin autorización.
6. Mantener el proyecto compilable.
7. Ejecutar las verificaciones disponibles después de cambios importantes.

Este archivo es la referencia principal del proyecto.





## Estado actual — 2026-09-22

### Firebase

- Firebase está conectado al proyecto Flutter.

- Firebase Authentication funciona con email/contraseña.

- Firestore está configurado y funcionando.

- El usuario puede registrarse e iniciar sesión.

- Al crear una cuenta sin negocio asociado, se muestra `BusinessSetupScreen`.

- Al crear el negocio se genera:

  - `businesses/{businessId}`

  - `users/{uid}` con el campo `businessId`.

### Flujo actual

```text

Login / Registro

      ↓

AppRouter

      ↓

¿El usuario tiene businessId?

   ├── NO → BusinessSetupScreen

   │          ↓

   │       Crear negocio

   │

   └── SÍ → BusinessHomeScreen

                ↓

             Categorías