-- Migracion: jornadas operativas controladas por el usuario.
-- Ejecutar en Supabase SQL Editor antes de desplegar la app.

CREATE TABLE IF NOT EXISTS jornadas (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha_apertura TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_cierre   TIMESTAMPTZ,
  cerrada        BOOLEAN NOT NULL DEFAULT false,
  nota_cierre    TEXT,
  creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE ventas
  ADD COLUMN IF NOT EXISTS jornada_id UUID REFERENCES jornadas(id) ON DELETE SET NULL;

ALTER TABLE base_dia
  ADD COLUMN IF NOT EXISTS jornada_id UUID REFERENCES jornadas(id) ON DELETE SET NULL;

ALTER TABLE cierres_dia
  ADD COLUMN IF NOT EXISTS jornada_id UUID REFERENCES jornadas(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_jornadas_unica_abierta
  ON jornadas(usuario_id)
  WHERE cerrada = false;

CREATE UNIQUE INDEX IF NOT EXISTS idx_base_dia_jornada
  ON base_dia(jornada_id)
  WHERE jornada_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_cierres_dia_jornada
  ON cierres_dia(jornada_id)
  WHERE jornada_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_jornadas_usuario_estado
  ON jornadas(usuario_id, cerrada, fecha_apertura DESC);

CREATE INDEX IF NOT EXISTS idx_ventas_jornada
  ON ventas(jornada_id, creado_en DESC);

ALTER TABLE jornadas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "jornadas_propias" ON jornadas;
CREATE POLICY "jornadas_propias"
  ON jornadas FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "base_dia_propias" ON base_dia;
CREATE POLICY "base_dia_propias"
  ON base_dia FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);
