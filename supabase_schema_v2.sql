-- ═══════════════════════════════════════════════════════════
-- BlizzShop — Migración BD v2
-- Ejecutar en Supabase → SQL Editor
-- ═══════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════════
-- 1. TABLA PERFILES (nueva)
-- ═══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS perfiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre      TEXT NOT NULL DEFAULT '',
  nombre_bar  TEXT NOT NULL DEFAULT '',
  creado_en   TIMESTAMPTZ DEFAULT now()
);

-- Trigger: crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre, nombre_bar)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', ''),
    COALESCE(NEW.raw_user_meta_data->>'nombre_bar', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═══════════════════════════════════════════
-- 2. AGREGAR usuario_id A TABLAS EXISTENTES
-- ═══════════════════════════════════════════
ALTER TABLE categorias
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS descripcion TEXT,
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#e8a838';

ALTER TABLE presentaciones
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE productos
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE movimientos_inventario
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS valor NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS proveedor TEXT;

-- Ampliar CHECK de tipo en movimientos para incluir 'venta'
ALTER TABLE movimientos_inventario
  DROP CONSTRAINT IF EXISTS movimientos_inventario_tipo_check;
ALTER TABLE movimientos_inventario
  ADD CONSTRAINT movimientos_inventario_tipo_check
  CHECK (tipo IN ('entrada', 'salida', 'ajuste', 'venta'));

-- ═══════════════════════════════════════════
-- 3. NUEVAS TABLAS
-- ═══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS ventas (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total       NUMERIC(12,2) NOT NULL DEFAULT 0,
  costo_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  nota        TEXT,
  creado_en   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS venta_items (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venta_id         UUID NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  producto_id      UUID REFERENCES productos(id) ON DELETE SET NULL,
  nombre_producto  TEXT NOT NULL,
  cantidad         INT NOT NULL,
  precio_unitario  NUMERIC(12,2) NOT NULL,
  costo_unitario   NUMERIC(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS cierres_dia (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha          DATE NOT NULL,
  total_ventas   NUMERIC(12,2) NOT NULL DEFAULT 0,
  costo_total    NUMERIC(12,2) NOT NULL DEFAULT 0,
  transacciones  INT NOT NULL DEFAULT 0,
  items_vendidos INT NOT NULL DEFAULT 0,
  nota           TEXT,
  creado_en      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(usuario_id, fecha)
);

-- ═══════════════════════════════════════════
-- 4. ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════
ALTER TABLE perfiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias           ENABLE ROW LEVEL SECURITY;
ALTER TABLE presentaciones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos            ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_inventario ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas               ENABLE ROW LEVEL SECURITY;
ALTER TABLE venta_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cierres_dia          ENABLE ROW LEVEL SECURITY;

-- Limpiar políticas anteriores
DROP POLICY IF EXISTS "perfil_propio"         ON perfiles;
DROP POLICY IF EXISTS "categorias_propias"    ON categorias;
DROP POLICY IF EXISTS "presentaciones_propias" ON presentaciones;
DROP POLICY IF EXISTS "productos_propios"     ON productos;
DROP POLICY IF EXISTS "movimientos_propios"   ON movimientos_inventario;
DROP POLICY IF EXISTS "ventas_propias"        ON ventas;
DROP POLICY IF EXISTS "items_ventas_propios"  ON venta_items;
DROP POLICY IF EXISTS "cierres_propios"       ON cierres_dia;

-- Crear políticas: cada usuario solo accede a sus propios datos
CREATE POLICY "perfil_propio"
  ON perfiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "categorias_propias"
  ON categorias FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "presentaciones_propias"
  ON presentaciones FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "productos_propios"
  ON productos FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "movimientos_propios"
  ON movimientos_inventario FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "ventas_propias"
  ON ventas FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "items_ventas_propios"
  ON venta_items FOR ALL
  USING (venta_id IN (SELECT id FROM ventas WHERE usuario_id = auth.uid()));

CREATE POLICY "cierres_propios"
  ON cierres_dia FOR ALL USING (auth.uid() = usuario_id);

-- ═══════════════════════════════════════════
-- 5. ÍNDICES
-- ═══════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_cat_usuario       ON categorias(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pres_usuario      ON presentaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_prod_usuario      ON productos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_movs_producto     ON movimientos_inventario(producto_id);
CREATE INDEX IF NOT EXISTS idx_movs_usuario      ON movimientos_inventario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_movs_fecha        ON movimientos_inventario(usuario_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_ventas_usuario    ON ventas(usuario_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_vitems_venta      ON venta_items(venta_id);
CREATE INDEX IF NOT EXISTS idx_cierres_ufecha    ON cierres_dia(usuario_id, fecha DESC);

-- ═══════════════════════════════════════════
-- NOTA: datos existentes sin usuario_id
-- ═══════════════════════════════════════════
-- Si tenías datos de prueba sin usuario_id, puedes asignarlos
-- manualmente con:
--   UPDATE categorias SET usuario_id = '<tu-uuid>' WHERE usuario_id IS NULL;
--   UPDATE presentaciones SET usuario_id = '<tu-uuid>' WHERE usuario_id IS NULL;
--   UPDATE productos SET usuario_id = '<tu-uuid>' WHERE usuario_id IS NULL;
--   UPDATE movimientos_inventario SET usuario_id = '<tu-uuid>' WHERE usuario_id IS NULL;
-- O simplemente borra los datos de prueba y empieza con datos reales.
