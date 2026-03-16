-- Migration: Affiliate System & Product Recommendations
-- Phase 3: Monetization through affiliate partnerships

-- Affiliate partners table
CREATE TABLE IF NOT EXISTS affiliate_partners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  logo_url TEXT,
  website_url TEXT,
  affiliate_code TEXT UNIQUE NOT NULL, -- Partner unique identifier
  commission_rate DECIMAL(5,2) DEFAULT 0.00, -- Commission percentage (e.g., 10.50 for 10.5%)
  is_active BOOLEAN DEFAULT true,
  partner_type TEXT DEFAULT 'product', -- 'product', 'service', 'food', 'insurance'
  category TEXT, -- 'food', 'toys', 'health', 'accessories', 'insurance'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Product recommendations table
CREATE TABLE IF NOT EXISTS product_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partner_id UUID REFERENCES affiliate_partners(id) ON DELETE CASCADE NOT NULL,
  product_name TEXT NOT NULL,
  product_description TEXT,
  product_image_url TEXT,
  product_url TEXT NOT NULL, -- Affiliate link
  product_price DECIMAL(10,2),
  currency TEXT DEFAULT 'TRY',
  category TEXT, -- 'food', 'toys', 'health', 'accessories'
  tags TEXT[], -- Array of tags for filtering
  target_pet_types TEXT[], -- ['dog', 'cat', 'bird', etc.]
  target_conditions TEXT[], -- ['overweight', 'skin_issues', 'dental_problems', etc.]
  recommendation_reason TEXT, -- Why this product is recommended
  priority INTEGER DEFAULT 0, -- Higher priority = shown first
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  click_count INTEGER DEFAULT 0,
  purchase_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Recommendation triggers table (when to show recommendations)
CREATE TABLE IF NOT EXISTS recommendation_triggers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trigger_type TEXT NOT NULL CHECK (trigger_type IN ('health_score', 'condition', 'log_parameter', 'expense_category', 'pet_type', 'behavioral')),
  trigger_key TEXT NOT NULL, -- e.g., 'weight', 'dental_score', 'food_category'
  trigger_value TEXT, -- e.g., 'overweight', 'low', 'dry_food'
  trigger_operator TEXT DEFAULT 'equals' CHECK (trigger_operator IN ('equals', 'less_than', 'greater_than', 'contains', 'in')),
  product_recommendation_id UUID REFERENCES product_recommendations(id) ON DELETE CASCADE NOT NULL,
  priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Click tracking table (affiliate link clicks)
CREATE TABLE IF NOT EXISTS affiliate_clicks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_recommendation_id UUID REFERENCES product_recommendations(id) ON DELETE CASCADE NOT NULL,
  partner_id UUID REFERENCES affiliate_partners(id) ON DELETE CASCADE NOT NULL,
  clicked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  ip_address TEXT, -- For analytics
  user_agent TEXT, -- For analytics
  source TEXT, -- 'health_screen', 'finance_screen', 'recommendation_widget', etc.
  pet_id UUID REFERENCES pets(id) ON DELETE SET NULL, -- If recommendation was pet-specific
  metadata JSONB DEFAULT '{}'::jsonb, -- Additional data
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Purchase tracking table (conversions - requires partner webhook or manual tracking)
CREATE TABLE IF NOT EXISTS affiliate_purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  affiliate_click_id UUID REFERENCES affiliate_clicks(id) ON DELETE SET NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  partner_id UUID REFERENCES affiliate_partners(id) ON DELETE CASCADE NOT NULL,
  product_recommendation_id UUID REFERENCES product_recommendations(id) ON DELETE SET NULL,
  purchase_amount DECIMAL(10,2),
  commission_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'TRY',
  purchase_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  transaction_id TEXT, -- Partner transaction ID
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'paid', 'cancelled')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- User recommendation preferences (to track what user has seen/dismissed)
CREATE TABLE IF NOT EXISTS user_recommendation_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  product_recommendation_id UUID REFERENCES product_recommendations(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('viewed', 'dismissed', 'interested', 'purchased')),
  action_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  metadata JSONB DEFAULT '{}'::jsonb,
  UNIQUE(user_id, product_recommendation_id, action)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_recommendations_partner_id ON product_recommendations(partner_id);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_category ON product_recommendations(category);
CREATE INDEX IF NOT EXISTS idx_product_recommendations_is_active ON product_recommendations(is_active);
CREATE INDEX IF NOT EXISTS idx_recommendation_triggers_product_id ON recommendation_triggers(product_recommendation_id);
CREATE INDEX IF NOT EXISTS idx_recommendation_triggers_type ON recommendation_triggers(trigger_type);
CREATE INDEX IF NOT EXISTS idx_affiliate_clicks_user_id ON affiliate_clicks(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_clicks_product_id ON affiliate_clicks(product_recommendation_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_clicks_clicked_at ON affiliate_clicks(clicked_at);
CREATE INDEX IF NOT EXISTS idx_affiliate_purchases_user_id ON affiliate_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_purchases_partner_id ON affiliate_purchases(partner_id);
CREATE INDEX IF NOT EXISTS idx_user_recommendation_prefs_user_id ON user_recommendation_preferences(user_id);

-- Insert default affiliate partners (examples)
INSERT INTO affiliate_partners (name, description, affiliate_code, partner_type, category, is_active) VALUES
('Pet Shop X', 'Premium pet food ve aksesuarlar', 'petshopx', 'product', 'food', true),
('VetCare Market', 'Veteriner ürünleri ve sağlık ürünleri', 'vetcare', 'product', 'health', true),
('ToyWorld Pets', 'Oyuncak ve eğlence ürünleri', 'toyworld', 'product', 'toys', true),
('Pet Insurance Co', 'Pet sigorta hizmetleri', 'petins', 'service', 'insurance', true)
ON CONFLICT (affiliate_code) DO NOTHING;

-- Insert sample product recommendations
INSERT INTO product_recommendations (partner_id, product_name, product_description, product_url, product_price, category, target_pet_types, recommendation_reason, is_featured, is_active)
SELECT 
  p.id,
  'Premium Köpek Maması',
  'Yaşlı köpekler için özel formüle edilmiş premium mama',
  'https://example.com/product/premium-dog-food?ref=petai',
  299.99,
  'food',
  ARRAY['dog'],
  'Yaşlı köpekler için dengeli beslenme',
  true,
  true
FROM affiliate_partners p WHERE p.affiliate_code = 'petshopx'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Function to track affiliate clicks
CREATE OR REPLACE FUNCTION track_affiliate_click(
  p_user_id UUID,
  p_product_recommendation_id UUID,
  p_source TEXT,
  p_pet_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_partner_id UUID;
  v_click_id UUID;
BEGIN
  -- Get partner ID from product recommendation
  SELECT partner_id INTO v_partner_id
  FROM product_recommendations
  WHERE id = p_product_recommendation_id;
  
  IF v_partner_id IS NULL THEN
    RAISE EXCEPTION 'Product recommendation not found';
  END IF;
  
  -- Insert click tracking
  INSERT INTO affiliate_clicks (
    user_id,
    product_recommendation_id,
    partner_id,
    source,
    pet_id
  )
  VALUES (
    p_user_id,
    p_product_recommendation_id,
    v_partner_id,
    p_source,
    p_pet_id
  )
  RETURNING id INTO v_click_id;
  
  -- Update click count on product recommendation
  UPDATE product_recommendations
  SET click_count = click_count + 1
  WHERE id = p_product_recommendation_id;
  
  RETURN v_click_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recommendations based on triggers
CREATE OR REPLACE FUNCTION get_recommendations_for_pet(
  p_pet_id UUID,
  p_user_id UUID,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  recommendation_id UUID,
  product_name TEXT,
  product_description TEXT,
  product_image_url TEXT,
  product_url TEXT,
  product_price DECIMAL,
  recommendation_reason TEXT,
  partner_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    pr.id,
    pr.product_name,
    pr.product_description,
    pr.product_image_url,
    pr.product_url,
    pr.product_price,
    pr.recommendation_reason,
    ap.name as partner_name
  FROM product_recommendations pr
  JOIN affiliate_partners ap ON pr.partner_id = ap.id
  JOIN recommendation_triggers rt ON rt.product_recommendation_id = pr.id
  JOIN pets p ON p.id = p_pet_id
  LEFT JOIN user_recommendation_preferences urp ON urp.user_id = p_user_id 
    AND urp.product_recommendation_id = pr.id 
    AND urp.action = 'dismissed'
  WHERE pr.is_active = true
    AND ap.is_active = true
    AND rt.is_active = true
    AND urp.id IS NULL -- Not dismissed by user
    AND (
      -- Pet type match
      pr.target_pet_types IS NULL OR p.type = ANY(pr.target_pet_types)
    )
  ORDER BY pr.is_featured DESC, pr.priority DESC, pr.click_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE affiliate_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recommendation_preferences ENABLE ROW LEVEL SECURITY;

-- RLS: Anyone can view active partners
CREATE POLICY "Anyone can view active affiliate partners" ON affiliate_partners
  FOR SELECT USING (is_active = true);

-- RLS: Anyone can view active product recommendations
CREATE POLICY "Anyone can view active product recommendations" ON product_recommendations
  FOR SELECT USING (is_active = true);

-- RLS: Anyone can view active triggers
CREATE POLICY "Anyone can view active recommendation triggers" ON recommendation_triggers
  FOR SELECT USING (is_active = true);

-- RLS: Users can view their own clicks
CREATE POLICY "Users can view their own affiliate clicks" ON affiliate_clicks
  FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

-- RLS: System can insert clicks (via function)
CREATE POLICY "System can insert affiliate clicks" ON affiliate_clicks
  FOR INSERT WITH CHECK (true);

-- RLS: Users can view their own purchases
CREATE POLICY "Users can view their own affiliate purchases" ON affiliate_purchases
  FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

-- RLS: System can insert purchases (via webhook)
CREATE POLICY "System can insert affiliate purchases" ON affiliate_purchases
  FOR INSERT WITH CHECK (true);

-- RLS: Users can view their own preferences
CREATE POLICY "Users can view their own recommendation preferences" ON user_recommendation_preferences
  FOR SELECT USING (auth.uid() = user_id);

-- RLS: Users can insert their own preferences
CREATE POLICY "Users can insert their own recommendation preferences" ON user_recommendation_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS: Users can update their own preferences
CREATE POLICY "Users can update their own recommendation preferences" ON user_recommendation_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- Grants
GRANT SELECT ON affiliate_partners TO authenticated;
GRANT SELECT ON product_recommendations TO authenticated;
GRANT SELECT ON recommendation_triggers TO authenticated;
GRANT SELECT, INSERT ON affiliate_clicks TO authenticated;
GRANT SELECT ON affiliate_purchases TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_recommendation_preferences TO authenticated;
