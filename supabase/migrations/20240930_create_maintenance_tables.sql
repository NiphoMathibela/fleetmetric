-- Vehicle Maintenance & Invoice Tracking Migration
-- Run this in Supabase SQL Editor

-- Create service_invoices storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('service-invoices', 'service-invoices', false)
ON CONFLICT (id) DO NOTHING;

-- Create vehicle_services table
CREATE TABLE IF NOT EXISTS vehicle_services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  workshop_name TEXT NOT NULL,
  invoice_date DATE NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  odometer_reading INTEGER NOT NULL,
  invoice_path TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create service_items table
CREATE TABLE IF NOT EXISTS service_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  service_id UUID NOT NULL REFERENCES vehicle_services(id) ON DELETE CASCADE,
  category TEXT NOT NULL, -- e.g., 'brake_pads_front', 'engine_oil', 'air_filter', 'labor'
  description TEXT,
  amount DECIMAL(10, 2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  unit TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create maintenance_schedules table (if not exists, update it)
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  component_name TEXT NOT NULL, -- e.g., 'Brake Pads Front', 'Engine Oil'
  component_key TEXT NOT NULL, -- e.g., 'brake_pads_front', 'engine_oil'
  interval_km INTEGER NOT NULL, -- e.g., 50000 for brake pads, 10000 for oil
  interval_days INTEGER, -- e.g., 365 for annual services
  last_service_km INTEGER,
  last_service_date DATE,
  next_due_km INTEGER,
  next_due_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vehicle_id, component_key)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_vehicle_services_user_id ON vehicle_services(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_services_vehicle_id ON vehicle_services(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_services_date ON vehicle_services(invoice_date DESC);
CREATE INDEX IF NOT EXISTS idx_service_items_service_id ON service_items(service_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedules_vehicle_id ON maintenance_schedules(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedules_component ON maintenance_schedules(vehicle_id, component_key);

-- Enable Row Level Security
ALTER TABLE vehicle_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;

-- RLS Policies for vehicle_services
CREATE POLICY "Users can view their own vehicle services"
  ON vehicle_services FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vehicle services"
  ON vehicle_services FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vehicle services"
  ON vehicle_services FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vehicle services"
  ON vehicle_services FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for service_items
CREATE POLICY "Users can view service items through services"
  ON service_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vehicle_services 
      WHERE vehicle_services.id = service_items.service_id 
      AND vehicle_services.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert service items through their services"
  ON service_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicle_services 
      WHERE vehicle_services.id = service_items.service_id 
      AND vehicle_services.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update service items through their services"
  ON service_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vehicle_services 
      WHERE vehicle_services.id = service_items.service_id 
      AND vehicle_services.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete service items through their services"
  ON service_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM vehicle_services 
      WHERE vehicle_services.id = service_items.service_id 
      AND vehicle_services.user_id = auth.uid()
    )
  );

-- RLS Policies for maintenance_schedules
CREATE POLICY "Users can view their own maintenance schedules"
  ON maintenance_schedules FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own maintenance schedules"
  ON maintenance_schedules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own maintenance schedules"
  ON maintenance_schedules FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own maintenance schedules"
  ON maintenance_schedules FOR DELETE
  USING (auth.uid() = user_id);

-- Storage Policy for service-invoices bucket
CREATE POLICY "Users can upload service invoices"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'service-invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own service invoices"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'service-invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own service invoices"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'service-invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_vehicle_services_updated_at
  BEFORE UPDATE ON vehicle_services
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_schedules_updated_at
  BEFORE UPDATE ON maintenance_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate next due dates for maintenance
CREATE OR REPLACE FUNCTION calculate_next_due(
  p_vehicle_id UUID,
  p_component_key TEXT,
  p_current_km INTEGER,
  p_current_date DATE
)
RETURNS TABLE(next_due_km INTEGER, next_due_date DATE) AS $$
DECLARE
  v_interval_km INTEGER;
  v_interval_days INTEGER;
BEGIN
  SELECT interval_km, interval_days INTO v_interval_km, v_interval_days
  FROM maintenance_schedules
  WHERE vehicle_id = p_vehicle_id AND component_key = p_component_key;

  RETURN QUERY SELECT
    p_current_km + v_interval_km AS next_due_km,
    p_current_date + (v_interval_days || ' days')::INTERVAL AS next_due_date;
END;
$$ LANGUAGE plpgsql;

-- Insert default maintenance schedules for new vehicles
CREATE OR REPLACE FUNCTION create_default_maintenance_schedules(p_vehicle_id UUID, p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO maintenance_schedules (user_id, vehicle_id, component_name, component_key, interval_km, interval_days)
  VALUES
    (p_user_id, p_vehicle_id, 'Engine Oil', 'engine_oil', 10000, 365),
    (p_user_id, p_vehicle_id, 'Oil Filter', 'oil_filter', 10000, 365),
    (p_user_id, p_vehicle_id, 'Air Filter', 'air_filter', 20000, 730),
    (p_user_id, p_vehicle_id, 'Fuel Filter', 'fuel_filter', 40000, 1460),
    (p_user_id, p_vehicle_id, 'Spark Plugs', 'spark_plugs', 40000, 1460),
    (p_user_id, p_vehicle_id, 'Brake Pads Front', 'brake_pads_front', 50000, 1825),
    (p_user_id, p_vehicle_id, 'Brake Pads Rear', 'brake_pads_rear', 50000, 1825),
    (p_user_id, p_vehicle_id, 'Brake Discs Front', 'brake_discs_front', 80000, 3650),
    (p_user_id, p_vehicle_id, 'Brake Discs Rear', 'brake_discs_rear', 80000, 3650),
    (p_user_id, p_vehicle_id, 'Coolant', 'coolant', 40000, 1825),
    (p_user_id, p_vehicle_id, 'Transmission Fluid', 'transmission_fluid', 60000, 3650),
    (p_user_id, p_vehicle_id, 'Battery', 'battery', 80000, 1825),
    (p_user_id, p_vehicle_id, 'Tires', 'tires', 50000, 1825),
    (p_user_id, p_vehicle_id, 'Timing Belt', 'timing_belt', 100000, 3650),
    (p_user_id, p_vehicle_id, 'Cabin Air Filter', 'cabin_air_filter', 20000, 365)
  ON CONFLICT (vehicle_id, component_key) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
