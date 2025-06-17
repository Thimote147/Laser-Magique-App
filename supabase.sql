-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "moddatetime";

-- Drop existing tables if they exist
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS consumptions CASCADE;
DROP TABLE IF EXISTS stock_items CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS formulas CASCADE;
DROP TABLE IF EXISTS activities CASCADE;

-- Drop existing views if they exist
DROP VIEW IF EXISTS booking_summaries CASCADE;
DROP VIEW IF EXISTS low_stock_items CASCADE;
DROP VIEW IF EXISTS v_formula CASCADE;

-- Drop existing types if they exist
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS payment_type CASCADE;
DROP TYPE IF EXISTS item_category CASCADE;
DROP TYPE IF EXISTS theme_mode CASCADE;

-- Create ENUM types
CREATE TYPE payment_method AS ENUM ('card', 'cash', 'transfer');
CREATE TYPE payment_type AS ENUM ('deposit', 'balance');
CREATE TYPE item_category AS ENUM ('DRINK', 'FOOD', 'OTHER');
CREATE TYPE theme_mode AS ENUM ('system', 'light', 'dark');

-- Create activities table
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  price_per_person DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create formulas table
CREATE TABLE formulas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  min_persons INTEGER,
  max_persons INTEGER,
  default_game_count INTEGER,
  min_games INTEGER,
  max_games INTEGER,
  is_game_count_fixed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (min_persons > 0),
  CHECK (max_persons >= min_persons),
  CHECK (price >= 0)
);

-- Create formula view
CREATE OR REPLACE VIEW v_formula AS
SELECT 
    f.*,
    a.name as activity_name,
    a.description as activity_description,
    a.price_per_person
FROM formulas f
JOIN activities a ON f.activity_id = a.id;

-- Create customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name TEXT NOT NULL,
  last_name TEXT,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to safely create a customer
CREATE OR REPLACE FUNCTION create_customer(
  p_first_name TEXT,
  p_last_name TEXT,
  p_phone TEXT,
  p_email TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_customer_id UUID;
BEGIN
  INSERT INTO customers (
    first_name,
    last_name,
    phone,
    email
  )
  VALUES (
    p_first_name,
    p_last_name,
    p_phone,
    p_email
  )
  RETURNING id INTO v_customer_id;

  RETURN v_customer_id;
END;
$$;

-- Create bookings table
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  formula_id UUID REFERENCES formulas(id) ON DELETE RESTRICT,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  date_time TIMESTAMP WITH TIME ZONE NOT NULL,
  number_of_persons INTEGER NOT NULL,
  number_of_games INTEGER NOT NULL,
  is_cancelled BOOLEAN DEFAULT false,
  deposit DECIMAL(10,2) DEFAULT 0,
  payment_method payment_method DEFAULT 'card',
  total_paid DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (number_of_persons > 0),
  CHECK (number_of_games > 0),
  CHECK (deposit >= 0),
  CHECK (total_paid >= 0)
);

-- Create payments table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_method payment_method NOT NULL,
  payment_type payment_type NOT NULL,
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (amount > 0)
);

-- Create stock items table
CREATE TABLE stock_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  price DECIMAL(10,2) NOT NULL,
  alert_threshold INTEGER NOT NULL,
  category item_category NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (quantity >= 0),
  CHECK (price >= 0),
  CHECK (alert_threshold >= 0)
);

-- Create consumptions table
CREATE TABLE consumptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
  stock_item_id UUID REFERENCES stock_items(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (quantity > 0),
  CHECK (unit_price >= 0)
);

-- Create user settings table
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  notifications_enabled BOOLEAN DEFAULT true NOT NULL,
  theme_mode theme_mode DEFAULT 'system' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create automatic timestamp update triggers
CREATE TRIGGER handle_updated_at_activities
  BEFORE UPDATE ON activities
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_formulas
  BEFORE UPDATE ON formulas
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_bookings
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_payments
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_stock_items
  BEFORE UPDATE ON stock_items
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_consumptions
  BEFORE UPDATE ON consumptions
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at_user_settings
  BEFORE UPDATE ON user_settings
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

-- Create function to update stock quantities
CREATE OR REPLACE FUNCTION update_stock_quantity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Vérifier si le stock est suffisant
    IF NOT EXISTS (
      SELECT 1 
      FROM stock_items 
      WHERE id = NEW.stock_item_id 
      AND quantity >= NEW.quantity
    ) THEN
      RAISE EXCEPTION 'Stock insuffisant';
    END IF;
    
    UPDATE stock_items
    SET quantity = quantity - NEW.quantity
    WHERE id = NEW.stock_item_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE stock_items
    SET quantity = quantity + OLD.quantity
    WHERE id = OLD.stock_item_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.quantity <> OLD.quantity THEN
      -- Vérifier si le stock est suffisant pour l'augmentation de quantité
      IF NEW.quantity > OLD.quantity AND NOT EXISTS (
        SELECT 1 
        FROM stock_items 
        WHERE id = NEW.stock_item_id 
        AND quantity >= (NEW.quantity - OLD.quantity)
      ) THEN
        RAISE EXCEPTION 'Stock insuffisant pour l''augmentation de quantité';
      END IF;
      
      UPDATE stock_items
      SET quantity = quantity + (OLD.quantity - NEW.quantity)
      WHERE id = NEW.stock_item_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock updates
CREATE TRIGGER update_stock_after_consumption
  AFTER INSERT OR UPDATE OR DELETE ON consumptions
  FOR EACH ROW
  EXECUTE PROCEDURE update_stock_quantity();

-- Create function to update booking payments
CREATE OR REPLACE FUNCTION update_booking_payments()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE bookings
    SET total_paid = (
      SELECT COALESCE(SUM(amount), 0)
      FROM payments
      WHERE booking_id = NEW.booking_id
    )
    WHERE id = NEW.booking_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE bookings
    SET total_paid = (
      SELECT COALESCE(SUM(amount), 0)
      FROM payments
      WHERE booking_id = OLD.booking_id
    )
    WHERE id = OLD.booking_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for payment updates
CREATE TRIGGER update_booking_payments_after_change
  AFTER INSERT OR DELETE ON payments
  FOR EACH ROW
  EXECUTE PROCEDURE update_booking_payments();

-- Create booking_summaries view
CREATE OR REPLACE VIEW booking_summaries AS
SELECT 
  b.id,
  b.formula_id,
  cust.first_name,
  cust.last_name,
  cust.email,
  cust.phone,
  b.date_time,
  b.number_of_persons,
  b.number_of_games,
  b.is_cancelled,
  b.deposit,
  b.payment_method,
  b.total_paid,
  b.created_at,
  b.updated_at,
  f.price * b.number_of_persons * b.number_of_games AS formula_price,
  COALESCE(SUM(cons.quantity * cons.unit_price), 0) AS consumptions_total,
  (f.price * b.number_of_persons * b.number_of_games + COALESCE(SUM(cons.quantity * cons.unit_price), 0)) AS total_price,
  ((f.price * b.number_of_persons * b.number_of_games + COALESCE(SUM(cons.quantity * cons.unit_price), 0)) - b.total_paid) AS remaining_balance,
  json_agg(
    json_build_object(
      'id', cons.id,
      'item_id', cons.stock_item_id,
      'quantity', cons.quantity,
      'unit_price', cons.unit_price,
      'total_price', cons.quantity * cons.unit_price,
      'timestamp', cons.timestamp
    )
  ) FILTER (WHERE cons.id IS NOT NULL) AS consumptions,
  json_agg(
    json_build_object(
      'id', p.id,
      'amount', p.amount,
      'method', p.payment_method,
      'type', p.payment_type,
      'date', p.payment_date
    )
  ) FILTER (WHERE p.id IS NOT NULL) AS payments
FROM bookings b
LEFT JOIN formulas f ON b.formula_id = f.id
LEFT JOIN customers cust ON b.customer_id = cust.id
LEFT JOIN consumptions cons ON b.id = cons.booking_id
LEFT JOIN payments p ON b.id = p.booking_id
GROUP BY b.id, f.id, cust.id;

-- Create low_stock_items view
CREATE OR REPLACE VIEW low_stock_items AS
SELECT *
FROM stock_items
WHERE quantity <= alert_threshold;

-- Drop existing search_customers function if it exists
DROP FUNCTION IF EXISTS search_customers(TEXT);

-- Create search customers function
CREATE OR REPLACE FUNCTION search_customers(search_query TEXT)
RETURNS TABLE (
  id UUID,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  email TEXT,
  total_bookings BIGINT
) AS $$
BEGIN
  -- Si la requête est vide ou ne contient que des espaces, retourner une liste vide
  IF search_query IS NULL OR trim(search_query) = '' THEN
    RETURN QUERY
    SELECT
      c.id,
      c.first_name,
      c.last_name,
      c.phone,
      c.email,
      COUNT(b.id)::BIGINT as total_bookings
    FROM customers c
    LEFT JOIN bookings b ON c.id = b.customer_id
    WHERE false  -- Cette condition ne retournera aucun résultat
    GROUP BY c.id;
    RETURN;
  END IF;

  -- Sinon, effectuer la recherche normalement
  RETURN QUERY
  SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.phone,
    c.email,
    COUNT(b.id)::BIGINT as total_bookings
  FROM customers c
  LEFT JOIN bookings b ON c.id = b.customer_id
  WHERE 
    c.first_name ILIKE '%' || search_query || '%' OR
    c.last_name ILIKE '%' || search_query || '%' OR
    c.phone ILIKE '%' || search_query || '%' OR
    c.email ILIKE '%' || search_query || '%'
  GROUP BY c.id
  ORDER BY c.first_name, c.last_name;
END;
$$ LANGUAGE plpgsql;

-- Create function to create booking with payment
CREATE OR REPLACE FUNCTION create_booking_with_payment(
  p_formula_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_date_time TIMESTAMP WITH TIME ZONE,
  p_number_of_persons INTEGER,
  p_number_of_games INTEGER,
  p_deposit DECIMAL = 0,
  p_payment_method payment_method = 'card'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking_id UUID;
  v_customer_id UUID;
  v_formula RECORD;
BEGIN
  -- Vérifier la formule
  SELECT * INTO v_formula FROM formulas WHERE id = p_formula_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Formule invalide';
  END IF;

  -- Vérifier les contraintes de la formule
  IF p_number_of_persons < v_formula.min_persons THEN
    RAISE EXCEPTION 'Nombre de participants insuffisant';
  END IF;
  IF v_formula.max_persons IS NOT NULL AND p_number_of_persons > v_formula.max_persons THEN
    RAISE EXCEPTION 'Nombre de participants trop élevé';
  END IF;
  IF p_number_of_games < v_formula.min_games THEN
    RAISE EXCEPTION 'Nombre de parties insuffisant';
  END IF;
  IF v_formula.max_games IS NOT NULL AND p_number_of_games > v_formula.max_games THEN
    RAISE EXCEPTION 'Nombre de parties trop élevé';
  END IF;

  -- Rechercher le client existant ou en créer un nouveau
  SELECT id INTO v_customer_id
  FROM customers
  WHERE (phone IS NOT NULL AND phone = p_phone)
     OR (email IS NOT NULL AND email = p_email)
  LIMIT 1;

  IF v_customer_id IS NULL THEN
    -- Créer un nouveau client
    INSERT INTO customers (first_name, last_name, phone, email)
    VALUES (p_first_name, p_last_name, p_phone, p_email)
    RETURNING id INTO v_customer_id;
  ELSE
    -- Mettre à jour les informations du client existant si nécessaire
    UPDATE customers
    SET 
      first_name = COALESCE(NULLIF(p_first_name, ''), first_name),
      last_name = COALESCE(NULLIF(p_last_name, ''), last_name),
      phone = COALESCE(NULLIF(p_phone, ''), phone),
      email = COALESCE(NULLIF(p_email, ''), email)
    WHERE id = v_customer_id;
  END IF;

  -- Insérer la réservation
  INSERT INTO bookings (
    formula_id, 
    customer_id, 
    date_time, 
    number_of_persons, 
    number_of_games,
    deposit, 
    payment_method
  ) VALUES (
    p_formula_id,
    v_customer_id,
    p_date_time,
    p_number_of_persons,
    p_number_of_games,
    p_deposit,
    p_payment_method
  )
  RETURNING id INTO v_booking_id;

  -- Insérer le paiement de l'acompte si nécessaire
  IF p_deposit > 0 THEN
    INSERT INTO payments (
      booking_id,
      amount,
      payment_method,
      payment_type,
      payment_date
    ) VALUES (
      v_booking_id,
      p_deposit,
      p_payment_method,
      'deposit',
      NOW()
    );
  END IF;

  RETURN v_booking_id;
END;
$$;

-- Create function to update booking with customer
CREATE OR REPLACE FUNCTION update_booking_with_customer(
  p_booking_id UUID,
  p_formula_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_date_time TIMESTAMP WITH TIME ZONE,
  p_number_of_persons INTEGER,
  p_number_of_games INTEGER,
  p_is_cancelled BOOLEAN,
  p_deposit DECIMAL,
  p_payment_method payment_method
)
RETURNS record
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_customer_id UUID;
  v_formula RECORD;
  v_result record;
BEGIN
  -- Get the current customer_id from the booking
  SELECT b.customer_id, b.id AS booking_id INTO v_result
  FROM bookings b
  WHERE b.id = p_booking_id;

  IF v_result.booking_id IS NULL THEN
    RAISE EXCEPTION 'Réservation non trouvée';
  END IF;

  -- Store the customer_id
  v_customer_id := v_result.customer_id;

  -- Vérifier la formule
  SELECT * INTO v_formula FROM formulas WHERE id = p_formula_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Formule invalide';
  END IF;

  -- Vérifier les contraintes de la formule
  IF p_number_of_persons < v_formula.min_persons THEN
    RAISE EXCEPTION 'Nombre de participants insuffisant';
  END IF;
  IF v_formula.max_persons IS NOT NULL AND p_number_of_persons > v_formula.max_persons THEN
    RAISE EXCEPTION 'Nombre de participants trop élevé';
  END IF;
  IF p_number_of_games < v_formula.min_games THEN
    RAISE EXCEPTION 'Nombre de parties insuffisant';
  END IF;
  IF v_formula.max_games IS NOT NULL AND p_number_of_games > v_formula.max_games THEN
    RAISE EXCEPTION 'Nombre de parties trop élevé';
  END IF;

  -- Update customer information
  UPDATE customers
  SET 
    first_name = COALESCE(NULLIF(p_first_name, ''), first_name),
    last_name = COALESCE(NULLIF(p_last_name, ''), last_name),
    phone = COALESCE(NULLIF(p_phone, ''), phone),
    email = COALESCE(NULLIF(p_email, ''), email)
  WHERE id = v_customer_id;

  -- Update booking
  UPDATE bookings
  SET 
    formula_id = p_formula_id,
    date_time = p_date_time,
    number_of_persons = p_number_of_persons,
    number_of_games = p_number_of_games,
    is_cancelled = p_is_cancelled,
    deposit = p_deposit,
    payment_method = p_payment_method
  WHERE id = p_booking_id;

  -- Return the updated booking details from booking_summaries view
  SELECT * INTO v_result
  FROM booking_summaries
  WHERE id = p_booking_id;

  IF v_result.id IS NULL THEN
    RAISE EXCEPTION 'Erreur lors de la mise à jour de la réservation';
  END IF;

  RETURN v_result;
END;
$$;

-- Create function to cancel a booking
CREATE OR REPLACE FUNCTION cancel_booking(
  p_booking_id UUID
)
RETURNS record
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking_exists BOOLEAN;
  v_result record;
BEGIN
  -- Check if booking exists
  SELECT EXISTS(
    SELECT 1 FROM bookings WHERE id = p_booking_id
  ) INTO v_booking_exists;

  IF NOT v_booking_exists THEN
    RAISE EXCEPTION 'La réservation avec l''ID % n''existe pas', p_booking_id;
  END IF;

  -- Update booking to cancelled status
  UPDATE bookings
  SET is_cancelled = true
  WHERE id = p_booking_id;

  -- Return the updated booking details from booking_summaries view
  SELECT * INTO v_result
  FROM booking_summaries
  WHERE id = p_booking_id;

  RETURN v_result;
END;
$$;

-- Enable Row Level Security (RLS)
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE formulas ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
CREATE POLICY "Allow all operations for everyone"
  ON activities FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations for everyone"
  ON formulas FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable all for authenticated users"
  ON bookings FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable all for authenticated users"
  ON payments FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable all for authenticated users"
  ON stock_items FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable all for authenticated users"
  ON consumptions FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can manage their own settings"
  ON user_settings FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_bookings_date_time ON bookings(date_time);
CREATE INDEX idx_bookings_formula ON bookings(formula_id);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_consumptions_booking ON consumptions(booking_id);
CREATE INDEX idx_consumptions_stock_item ON consumptions(stock_item_id);
CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_formulas_activity ON formulas(activity_id);
CREATE INDEX idx_stock_items_category ON stock_items(category);
CREATE INDEX idx_user_settings_user ON user_settings(user_id);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_name ON customers(first_name, last_name);

-- Insert initial data
INSERT INTO customers(first_name, last_name, email, phone) 
VALUES ('Thimoté', 'Fétu', 'thimotefetu@gmail.com', '0492504409');

INSERT INTO activities(name, description, price_per_person) 
VALUES ('Laser Game', 'OK', 8.00);

INSERT INTO formulas(
  activity_id, 
  name, 
  description, 
  price, 
  min_persons, 
  max_persons, 
  default_game_count, 
  is_game_count_fixed
)
VALUES ((SELECT id FROM activities WHERE name = 'Laser Game'), 'Groupe', 'OK', 8.00, 2, 20, 1, false);