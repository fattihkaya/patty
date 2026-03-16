-- Expense Management SQL Queries
-- Tüm harcama yönetimi sorguları

-- ============================================
-- 1. KATEGORİLER (EXPENSE CATEGORIES)
-- ============================================

-- Tüm kategorileri getir (alfabetik sıralı)
SELECT 
    id,
    name,
    icon_name,
    color,
    created_at
FROM expense_categories
ORDER BY name ASC;

-- ============================================
-- 2. HARCAMALAR (EXPENSES)
-- ============================================

-- Bir pet'e ait tüm harcamaları getir (tarih sıralı - en yeni önce)
SELECT 
    id,
    pet_id,
    user_id,
    category_id,
    amount,
    description,
    expense_date,
    receipt_url,
    is_recurring,
    recurring_interval_days,
    created_at,
    updated_at
FROM expenses
WHERE pet_id = :pet_id
ORDER BY expense_date DESC;

-- Tarih aralığına göre harcamaları getir
SELECT 
    id,
    pet_id,
    user_id,
    category_id,
    amount,
    description,
    expense_date,
    receipt_url,
    is_recurring,
    recurring_interval_days,
    created_at,
    updated_at
FROM expenses
WHERE pet_id = :pet_id
    AND expense_date >= :start_date
    AND expense_date <= :end_date
ORDER BY expense_date DESC;

-- Belirli bir kategoriye ait harcamaları getir
SELECT 
    e.*,
    ec.name as category_name,
    ec.icon_name as category_icon,
    ec.color as category_color
FROM expenses e
LEFT JOIN expense_categories ec ON e.category_id = ec.id
WHERE e.pet_id = :pet_id
    AND e.category_id = :category_id
ORDER BY e.expense_date DESC;

-- Toplam harcama (belirli bir pet için)
SELECT 
    COALESCE(SUM(amount), 0) as total_amount
FROM expenses
WHERE pet_id = :pet_id;

-- Toplam harcama (tarih aralığı ile)
SELECT 
    COALESCE(SUM(amount), 0) as total_amount
FROM expenses
WHERE pet_id = :pet_id
    AND expense_date >= :start_date
    AND expense_date <= :end_date;

-- Kategori bazında toplam harcamalar
SELECT 
    ec.id as category_id,
    ec.name as category_name,
    ec.icon_name,
    ec.color,
    COALESCE(SUM(e.amount), 0) as total_amount,
    COUNT(e.id) as expense_count
FROM expense_categories ec
LEFT JOIN expenses e ON ec.id = e.category_id AND e.pet_id = :pet_id
GROUP BY ec.id, ec.name, ec.icon_name, ec.color
ORDER BY total_amount DESC;

-- Aylık harcama özeti
SELECT 
    DATE_TRUNC('month', expense_date) as month,
    SUM(amount) as total_amount,
    COUNT(*) as expense_count
FROM expenses
WHERE pet_id = :pet_id
GROUP BY DATE_TRUNC('month', expense_date)
ORDER BY month DESC;

-- Yeni harcama ekle
INSERT INTO expenses (
    pet_id,
    user_id,
    category_id,
    amount,
    description,
    expense_date,
    receipt_url,
    is_recurring,
    recurring_interval_days
) VALUES (
    :pet_id,
    :user_id,
    :category_id,
    :amount,
    :description,
    :expense_date,
    :receipt_url,
    :is_recurring,
    :recurring_interval_days
)
RETURNING *;

-- Harcama güncelle
UPDATE expenses
SET 
    category_id = :category_id,
    amount = :amount,
    description = :description,
    expense_date = :expense_date,
    receipt_url = :receipt_url,
    is_recurring = :is_recurring,
    recurring_interval_days = :recurring_interval_days,
    updated_at = NOW()
WHERE id = :expense_id
    AND user_id = :user_id
RETURNING *;

-- Harcama sil
DELETE FROM expenses
WHERE id = :expense_id
    AND user_id = :user_id;

-- ============================================
-- 3. HATIRLATMALAR (EXPENSE REMINDERS)
-- ============================================

-- Aktif hatırlatmaları getir
SELECT 
    id,
    pet_id,
    user_id,
    expense_id,
    reminder_type,
    title,
    message,
    reminder_date,
    is_active,
    is_sent,
    created_at
FROM expense_reminders
WHERE pet_id = :pet_id
    AND user_id = :user_id
    AND is_active = true
    AND reminder_date >= CURRENT_DATE
ORDER BY reminder_date ASC;

-- Hatırlatma oluştur
INSERT INTO expense_reminders (
    pet_id,
    user_id,
    expense_id,
    reminder_type,
    title,
    message,
    reminder_date,
    is_active
) VALUES (
    :pet_id,
    :user_id,
    :expense_id,
    :reminder_type,
    :title,
    :message,
    :reminder_date,
    :is_active
)
RETURNING *;

-- Hatırlatmayı gönderildi olarak işaretle
UPDATE expense_reminders
SET is_sent = true
WHERE id = :reminder_id
    AND user_id = :user_id;

-- Hatırlatma sil
DELETE FROM expense_reminders
WHERE id = :reminder_id
    AND user_id = :user_id;

-- ============================================
-- 4. MAMA TAKİBİ (PET FOOD TRACKING)
-- ============================================

-- Bitmemiş mama takiplerini getir
SELECT 
    id,
    pet_id,
    user_id,
    food_name,
    purchase_date,
    estimated_days,
    estimated_finish_date,
    is_finished,
    created_at,
    updated_at
FROM pet_food_tracking
WHERE pet_id = :pet_id
    AND user_id = :user_id
    AND is_finished = false
ORDER BY estimated_finish_date ASC;

-- Mama takibi ekle
INSERT INTO pet_food_tracking (
    pet_id,
    user_id,
    food_name,
    purchase_date,
    estimated_days,
    estimated_finish_date,
    is_finished
) VALUES (
    :pet_id,
    :user_id,
    :food_name,
    :purchase_date,
    :estimated_days,
    :estimated_finish_date,
    false
)
RETURNING *;

-- Mama takibini güncelle
UPDATE pet_food_tracking
SET 
    food_name = :food_name,
    estimated_days = :estimated_days,
    estimated_finish_date = :estimated_finish_date,
    is_finished = :is_finished,
    updated_at = NOW()
WHERE id = :tracking_id
    AND user_id = :user_id
RETURNING *;

-- Mama takibini sil
DELETE FROM pet_food_tracking
WHERE id = :tracking_id
    AND user_id = :user_id;

-- ============================================
-- 5. İSTATİSTİKLER VE ANALİZLER
-- ============================================

-- Bu ay toplam harcama
SELECT 
    COALESCE(SUM(amount), 0) as total_amount
FROM expenses
WHERE pet_id = :pet_id
    AND expense_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND expense_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';

-- Bu yıl toplam harcama
SELECT 
    COALESCE(SUM(amount), 0) as total_amount
FROM expenses
WHERE pet_id = :pet_id
    AND expense_date >= DATE_TRUNC('year', CURRENT_DATE)
    AND expense_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year';

-- Geçen aya göre değişim yüzdesi
WITH this_month AS (
    SELECT COALESCE(SUM(amount), 0) as total
    FROM expenses
    WHERE pet_id = :pet_id
        AND expense_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND expense_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
),
last_month AS (
    SELECT COALESCE(SUM(amount), 0) as total
    FROM expenses
    WHERE pet_id = :pet_id
        AND expense_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND expense_date < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT 
    this_month.total as this_month_total,
    last_month.total as last_month_total,
    CASE 
        WHEN last_month.total > 0 
        THEN ((this_month.total - last_month.total) / last_month.total * 100)
        ELSE 0
    END as change_percentage
FROM this_month, last_month;

-- En çok harcama yapılan kategoriler (top 5)
SELECT 
    ec.name as category_name,
    ec.icon_name,
    ec.color,
    SUM(e.amount) as total_amount,
    COUNT(e.id) as expense_count
FROM expenses e
INNER JOIN expense_categories ec ON e.category_id = ec.id
WHERE e.pet_id = :pet_id
GROUP BY ec.id, ec.name, ec.icon_name, ec.color
ORDER BY total_amount DESC
LIMIT 5;

-- Tekrarlayan harcamalar
SELECT 
    id,
    pet_id,
    category_id,
    amount,
    description,
    expense_date,
    is_recurring,
    recurring_interval_days,
    expense_date + (recurring_interval_days || ' days')::INTERVAL as next_date
FROM expenses
WHERE pet_id = :pet_id
    AND is_recurring = true
    AND user_id = :user_id
ORDER BY expense_date DESC;

-- Kategori bazında harcama yüzdesi
SELECT 
    ec.name as category_name,
    ec.color,
    SUM(e.amount) as amount,
    ROUND(
        SUM(e.amount) * 100.0 / NULLIF(SUM(SUM(e.amount)) OVER(), 0), 
        2
    ) as percentage
FROM expenses e
INNER JOIN expense_categories ec ON e.category_id = ec.id
WHERE e.pet_id = :pet_id
GROUP BY ec.id, ec.name, ec.color
ORDER BY amount DESC;
