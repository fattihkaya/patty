-- Hızlı kurulum: expense_categories tablosu ve varsayılan kategoriler

-- 1. Tablo oluştur
CREATE TABLE IF NOT EXISTS expense_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  icon_name TEXT,
  color TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. RLS etkinleştir
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;

-- 3. Herkesin kategorileri görebilmesi için policy
DROP POLICY IF EXISTS "Anyone can view expense categories" ON expense_categories;
CREATE POLICY "Anyone can view expense categories" ON expense_categories FOR SELECT USING (true);

-- 4. Authenticated kullanıcılar için SELECT yetkisi
GRANT SELECT ON expense_categories TO authenticated;

-- 5. Varsayılan kategorileri ekle
INSERT INTO expense_categories (name, icon_name, color) VALUES
('Mama ve Beslenme', 'restaurant', '#FF6B6B'),
('Veteriner ve Sağlık', 'medical_services', '#4ECDC4'),
('Oyuncaklar', 'toys', '#FFE66D'),
('Aksesuarlar', 'shopping_bag', '#95E1D3'),
('Temizlik ve Bakım', 'cleaning_services', '#A8E6CF'),
('Sigorta', 'security', '#FFD3A5'),
('Diğer', 'more_horiz', '#C7CEEA')
ON CONFLICT DO NOTHING;
