-- Add current_odometer column to vehicles table
-- This will track the latest odometer reading from fuel slips and services

ALTER TABLE vehicles
ADD COLUMN IF NOT EXISTS current_odometer INTEGER DEFAULT 0;

-- Update current_odometer for existing vehicles based on their latest fuel slip or service
UPDATE vehicles v
SET current_odometer = GREATEST(
  COALESCE(
    (SELECT MAX(odometer_reading)
     FROM fuel_slips
     WHERE vehicle_id = v.id),
    0
  ),
  COALESCE(
    (SELECT MAX(odometer_reading)
     FROM vehicle_services
     WHERE vehicle_id = v.id),
    0
  ),
  starting_odometer
);
