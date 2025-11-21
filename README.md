# Sistema de Inventario Offline-First

Sistema de gestión de inventario para tiendas de electrónicos con soporte offline-first.

## 📱 Características

- ✅ Gestión de productos con categorías
- ✅ Control de inventario por ubicación (tiendas y almacenes)
- ✅ Registro de compras con actualización automática de stock
- ✅ Registro de ventas con validación de stock
- ✅ Transferencias de productos entre ubicaciones
- ✅ Sincronización offline-first
- ✅ Autenticación de empleados por ubicación
- ✅ Reportes de ventas y compras

## 🛠️ Stack Tecnológico

- **Frontend:** Flutter + Dart
- **Estado:** BLoC Pattern
- **Base de datos local:** Drift (SQLite)
- **Base de datos remota:** Supabase (PostgreSQL)
- **Autenticación:** Supabase Auth

## 📐 Arquitectura

El proyecto sigue Clean Architecture con las siguientes capas:
```
lib/
├── core/           # Configuraciones y utilidades
├── data/           # Datasources, Models, Repositories
├── domain/         # Entities, Repositories (contracts), UseCases
└── presentation/   # BLoC, Pages, Widgets
```

## 🔄 Sincronización Offline-First

1. Todas las operaciones se guardan primero en la base de datos local (Drift)
2. Si hay conexión, se sincronizan inmediatamente con Supabase
3. Si no hay conexión, se agregan a una cola de sincronización
4. Al recuperar la conexión, se procesan las operaciones pendientes
5. Triggers en Supabase manejan la actualización del inventario

## 🚀 Instalación

1. Clonar el repositorio
2. Copiar `lib/core/config/supabase_config.example.dart` a `supabase_config.dart`
3. Configurar las credenciales de Supabase
4. Ejecutar:
```bash
   flutter pub get
   dart run build_runner build
   flutter run
```

## 👤 Credenciales de Prueba

### 1. Administrador (Acceso Global)
| Campo | Valor |
|-------|-------|
| Email | `admin@test.com` |
| Password | `admin123` |
| Acceso | Todo el inventario global de todas las tiendas y almacenes |

### 2. Manager de Tienda
| Campo | Valor |
|-------|-------|
| Email | `manager1@test.com` |
| Password | `manager123` |
| Acceso | Inventario de "Tienda Centro" (ubicación asignada) |

### 3. Manager de Almacén
| Campo | Valor |
|-------|-------|
| Email | `manager2@test.com` |
| Password | `manager123` |
| Acceso | Inventario de "Almacén Principal" (ubicación asignada) |

### 4. Vendedor
| Campo | Valor |
|-------|-------|
| Email | `seller1@test.com` |
| Password | `seller123` |
| Acceso | Inventario de "Tienda Centro" (ubicación asignada) |

## 📊 Base de Datos

El sistema utiliza las siguientes tablas:

| Tabla | Descripción |
|-------|-------------|
| employees | Empleados del sistema |
| locations | Tiendas y almacenes |
| employee_locations | Relación empleado-ubicación |
| products | Catálogo de productos |
| inventory | Stock por producto y ubicación |
| purchases | Registro de compras |
| purchase_details | Detalle de productos comprados |
| sales | Registro de ventas |
| sale_details | Detalle de productos vendidos |
| transfers | Transferencias entre ubicaciones |
| transfer_details | Detalle de productos transferidos |
| sync_queue | Cola de sincronización offline |

## 🔐 Roles y Permisos

| Rol | Permisos |
|-----|----------|
| admin | Acceso total, todas las ubicaciones |
| manager | Gestión completa de su ubicación asignada |
| seller | Ventas y consultas en su ubicación asignada |



