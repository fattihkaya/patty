-- Migration: Subscription System & Usage Tracking
-- Phase 1: Monetization Infrastructure

-- Subscription plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL, -- 'free', 'premium', 'pro'
  display_name TEXT NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2) DEFAULT 0,
  price_yearly DECIMAL(10,2) DEFAULT 0,
  features JSONB NOT NULL DEFAULT '{}'::jsonb,
  trial_days INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- User subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  plan_id UUID REFERENCES subscription_plans(id) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'trial', 'grace_period')),
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMP WITH TIME ZONE,
  canceled_at TIMESTAMP WITH TIME ZONE,
  original_transaction_id TEXT, -- App Store/Play Store transaction ID
  revenuecat_customer_id TEXT, -- RevenueCat customer ID
  revenuecat_entitlements JSONB, -- RevenueCat entitlements data
  platform TEXT CHECK (platform IN ('ios', 'android')),
  billing_period TEXT CHECK (billing_period IN ('monthly', 'yearly')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Usage tracking table (rate limiting için)
CREATE TABLE IF NOT EXISTS usage_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  feature_type TEXT NOT NULL, -- 'ai_analysis', 'log_creation', 'pdf_export', 'pet_creation'
  usage_date DATE NOT NULL,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(user_id, feature_type, usage_date)
);

-- Subscription history (audit trail)
CREATE TABLE IF NOT EXISTS subscription_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  plan_id UUID REFERENCES subscription_plans(id),
  action TEXT NOT NULL, -- 'subscribed', 'upgraded', 'downgraded', 'canceled', 'renewed', 'expired'
  from_plan_id UUID REFERENCES subscription_plans(id),
  to_plan_id UUID REFERENCES subscription_plans(id),
  transaction_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_expires_at ON user_subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_date ON usage_tracking(user_id, usage_date);
CREATE INDEX IF NOT EXISTS idx_usage_tracking_feature ON usage_tracking(feature_type);

-- Insert default subscription plans
INSERT INTO subscription_plans (name, display_name, description, price_monthly, price_yearly, features, display_order) VALUES
(
  'free',
  'Ücretsiz',
  'Temel özelliklerle başla',
  0,
  0,
  '{
    "ai_analyses_per_month": 3,
    "max_pets": 1,
    "pdf_exports": false,
    "advanced_analytics": false,
    "ad_free": false,
    "priority_support": false,
    "custom_themes": false
  }'::jsonb,
  1
),
(
  'premium',
  'Premium',
  'Sınırsız AI analizi ve gelişmiş özellikler',
  0, -- Fiyatlar App Store/Play Store'da belirlenecek
  0,
  '{
    "ai_analyses_per_month": -1,
    "max_pets": -1,
    "pdf_exports": true,
    "advanced_analytics": true,
    "ad_free": true,
    "priority_support": false,
    "custom_themes": false,
    "priority_ai_processing": true
  }'::jsonb,
  2
),
(
  'pro',
  'Pro',
  'Tüm Premium özellikler + özel temalar ve öncelikli destek',
  0, -- Fiyatlar App Store/Play Store'da belirlenecek
  0,
  '{
    "ai_analyses_per_month": -1,
    "max_pets": -1,
    "pdf_exports": true,
    "advanced_analytics": true,
    "ad_free": true,
    "priority_support": true,
    "custom_themes": true,
    "priority_ai_processing": true,
    "advanced_export_formats": true,
    "api_access": false
  }'::jsonb,
  3
)
ON CONFLICT (name) DO NOTHING;

-- Function to initialize user with free plan
CREATE OR REPLACE FUNCTION initialize_user_subscription()
RETURNS TRIGGER AS $$
DECLARE
  free_plan_id UUID;
BEGIN
  -- Get free plan ID
  SELECT id INTO free_plan_id FROM subscription_plans WHERE name = 'free' LIMIT 1;
  
  IF free_plan_id IS NOT NULL THEN
    -- Create free subscription for new user
    INSERT INTO user_subscriptions (user_id, plan_id, status, started_at)
    VALUES (NEW.id, free_plan_id, 'active', NOW());
    
    -- Log subscription history
    INSERT INTO subscription_history (user_id, plan_id, action, to_plan_id)
    VALUES (NEW.id, free_plan_id, 'subscribed', free_plan_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-assign free plan to new users
DROP TRIGGER IF EXISTS on_profile_created_subscription ON profiles;
CREATE TRIGGER on_profile_created_subscription
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION initialize_user_subscription();

-- Function to check subscription expiry and update status
CREATE OR REPLACE FUNCTION check_subscription_expiry()
RETURNS void AS $$
BEGIN
  -- Update expired subscriptions
  UPDATE user_subscriptions
  SET status = 'expired',
      updated_at = NOW()
  WHERE status IN ('active', 'grace_period', 'trial')
    AND expires_at IS NOT NULL
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to get user's current plan features
CREATE OR REPLACE FUNCTION get_user_plan_features(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_features JSONB;
BEGIN
  SELECT sp.features INTO v_features
  FROM user_subscriptions us
  JOIN subscription_plans sp ON us.plan_id = sp.id
  WHERE us.user_id = p_user_id
    AND us.status = 'active'
    AND (us.expires_at IS NULL OR us.expires_at > NOW())
  LIMIT 1;
  
  -- Return free plan features if no active subscription
  IF v_features IS NULL THEN
    SELECT features INTO v_features
    FROM subscription_plans
    WHERE name = 'free'
    LIMIT 1;
  END IF;
  
  RETURN COALESCE(v_features, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Row Level Security (RLS)
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for subscription_plans
CREATE POLICY "Anyone can view active subscription plans" ON subscription_plans
  FOR SELECT USING (is_active = true);

-- RLS Policies for user_subscriptions
CREATE POLICY "Users can view their own subscription" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscription" ON user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- System can insert subscriptions (via triggers/functions)
CREATE POLICY "System can insert subscriptions" ON user_subscriptions
  FOR INSERT WITH CHECK (true);

-- RLS Policies for usage_tracking
CREATE POLICY "Users can view their own usage" ON usage_tracking
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own usage" ON usage_tracking
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own usage" ON usage_tracking
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for subscription_history
CREATE POLICY "Users can view their own subscription history" ON subscription_history
  FOR SELECT USING (auth.uid() = user_id);

-- Grant access to authenticated users
GRANT SELECT ON subscription_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON usage_tracking TO authenticated;
GRANT SELECT ON subscription_history TO authenticated;
