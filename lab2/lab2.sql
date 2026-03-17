TRUNCATE TABLE transactions, goals, categories, users RESTART IDENTITY CASCADE;

-- 2 task
INSERT INTO users (username, email, budget)
VALUES 
    ('Vasya', 'vasyapupkin@gmail.com', 10000),
    ('Fedya', 'fedya_mokin@mail.com', 15000.50),
    ('Masha', 'masha721193@yandex.ru', 20000)
ON CONFLICT (username) DO NOTHING;

SELECT '=== USERS ===' as " ";
SELECT * FROM users;

INSERT INTO categories (user_id, name, type)
VALUES 
    (1, 'salary', 'income'),
    (1, 'products', 'expense'),
    (1, 'car', 'expense'),
    (1, 'house', 'expense'),
    (2, 'pocket money', 'income'),
    (2, 'money from granny', 'income'),
    (2, 'sweets', 'expense'),
    (2, 'stationery', 'expense'),
    (3, 'salary', 'income'),
    (3, 'art', 'expense'),
    (3, 'bike', 'expense')
ON CONFLICT (user_id, name, type) DO NOTHING;

SELECT '=== Сategories ===' as " ";
SELECT * FROM categories;


INSERT INTO transactions (user_id, category_id, amount, date, description)
VALUES 
    --Vasya (user_id = 1)
    (1, 1, 50000, '2024-03-01', 'Monthly salary'),           
    (1, 2, 3500.50, '2024-03-02', 'Auchan'),                
    (1, 3, 2000, '2024-03-03', 'Petrol'),                    
    (1, 4, 7000, '2024-03-05', 'Communal services'),          
    (1, 2, 1200.75, '2024-03-07', 'Magnit'),                 
    
    -- Fedya (user_id = 2)
    (2, 5, 3000, '2024-03-01', 'Parents gave'),              
    (2, 6, 5000, '2024-03-02', 'Granny birthday'),       
    (2, 7, 450, '2024-03-03', 'Chocolate and cookies'),      
    (2, 8, 890.50, '2024-03-04', 'Notebooks and pens'),       
    (2, 7, 300, '2024-03-06', 'Ice cream'),                  
    
    -- Masha (user_id = 3)
    (3, 9, 45000, '2024-03-01', 'Salary march'),           
    (3, 10, 2500, '2024-03-02', 'Paint and brushes'),        
    (3, 11, 15000, '2024-03-03', 'New bicycle'),           
    (3, 10, 800, '2024-03-05', 'Canvas'),                  
    (3, 9, 45000, '2024-04-01', 'Salary april');          

SELECT '=== TRANSACTIONS ===' as " ";
SELECT * FROM transactions;

INSERT INTO goals (user_id, name, target_amount, current_amount, deadline)
VALUES 
    -- Vasya
    (1, 'New phone', 50000, 12000, '2024-06-01'),
    (1, 'Vacation', 100000, 35000, '2024-08-15'),
    
    -- Fedya
    (2, 'Laptop', 70000, 15000, '2024-09-01'),
    (2, 'Bicycle', 25000, 2500, '2024-07-01'),
    
    -- Masha
    (3, 'Art exhibition', 30000, 5000, '2024-05-20'),
    (3, 'New bike details', 10000, 2000, '2024-04-15')
ON CONFLICT (user_id, name) DO NOTHING;

SELECT '=== GOALS ===' as " ";
SELECT * FROM goals;
-- // 2 task

-- 3 task
INSERT INTO categories (user_id, name, type)
VALUES (1, 'entertainment', 'expense')
ON CONFLICT (user_id, name, type) DO NOTHING;

SELECT * FROM categories WHERE user_id = 1 AND name = 'entertainment';

UPDATE goals 
SET current_amount = current_amount + 5000
WHERE user_id = 3 AND name = 'New bike details';

UPDATE transactions 
SET amount = 600
WHERE user_id = 2 AND description = 'Ice cream' AND date = '2024-03-06';

SELECT '=== AFTER UPDATES ===' as " ";
SELECT * FROM goals WHERE user_id = 3;
SELECT * FROM transactions WHERE user_id = 2 AND description = 'Ice cream';

DELETE FROM transactions 
WHERE user_id = 1 AND description = 'Magnit' AND date = '2024-03-07';

SELECT * FROM transactions WHERE user_id = 1;
-- // 3 task

-- 4 task

SELECT '=== Agregates by users ===' as " ";

SELECT 
    u.username,
    COUNT(t.id) as transactions_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_transaction,
    MIN(t.amount) as min_transaction,
    MAX(t.amount) as max_transaction
FROM users u
LEFT JOIN transactions t ON u.id = t.user_id
GROUP BY u.id, u.username
ORDER BY total_spent DESC;

SELECT 
    COUNT(*) as total_transactions,
    SUM(amount) as total_amount,
    AVG(amount) as avg_transaction,
    MIN(amount) as min_transaction,
    MAX(amount) as max_transaction
FROM transactions;

-- // 4 task

-- 5 task

SELECT u.username, t.amount, c.name
FROM users u
JOIN transactions t ON u.id = t.user_id
JOIN categories c ON t.category_id = c.id;

-- LEFT JOIN
SELECT u.username, COUNT(t.id) as tx_count
FROM users u
LEFT JOIN transactions t ON u.id = t.user_id
GROUP BY u.id, u.username;

-- RIGHT JOIN
SELECT c.name, COUNT(t.id) as used_count
FROM transactions t
RIGHT JOIN categories c ON t.category_id = c.id
GROUP BY c.id, c.name;
-- // 5 task

-- 6 task
-- All transactions
CREATE VIEW all_transactions AS
SELECT 
    u.username,
    c.name as category,
    t.amount,
    t.date
FROM transactions t
JOIN users u ON t.user_id = u.id
JOIN categories c ON t.category_id = c.id;

-- Users total spent
CREATE VIEW user_totals AS
SELECT 
    u.username,
    COUNT(t.id) as operations,
    SUM(t.amount) as total
FROM users u
LEFT JOIN transactions t ON u.id = t.user_id
GROUP BY u.username;

-- How many times each category was used
CREATE VIEW category_stats AS
SELECT 
    c.name,
    c.type,
    COUNT(t.id) as used
FROM categories c
LEFT JOIN transactions t ON c.id = t.category_id
GROUP BY c.name, c.type;

SELECT * FROM all_transactions;
SELECT * FROM user_totals;
SELECT * FROM category_stats;
-- // 6 task