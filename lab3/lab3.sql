
-- удаленные транзакции
CREATE TABLE IF NOT EXISTS transactions_audit (
    audit_id SERIAL PRIMARY KEY,
    transaction_id INT,
    user_id INT,
    old_amount DECIMAL(15, 2),
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);
 
-- процент выполнения цели
CREATE OR REPLACE FUNCTION fn_get_goal_progress(goal_id_param INT)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
    v_target DECIMAL(15, 2);
    v_current DECIMAL(15, 2);
BEGIN
    SELECT target_amount, current_amount INTO v_target, v_current
    FROM goals WHERE id = goal_id_param;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Цель с ID % не найдена', goal_id_param;
    END IF;

    IF v_target = 0 THEN RETURN 0; END IF;

    RETURN (v_current / v_target) * 100;
END;
$$ LANGUAGE plpgsql;


-- добавление транзакции с проверкой категории
CREATE OR REPLACE PROCEDURE sp_add_transaction(
    p_user_id INT,
    p_category_id INT,
    p_amount DECIMAL(15, 2),
    p_description TEXT
) AS $$
DECLARE
    v_cat_user_id INT;
BEGIN
    SELECT user_id INTO v_cat_user_id FROM categories WHERE id = p_category_id;
    
    IF v_cat_user_id IS NULL THEN
        RAISE EXCEPTION 'Категория % не существует', p_category_id;
    END IF;

    IF v_cat_user_id != p_user_id THEN
        RAISE EXCEPTION 'Пользователь % не может использовать чужую категорию %', p_user_id, p_category_id;
    END IF;

    INSERT INTO transactions (user_id, category_id, amount, date, description)
    VALUES (p_user_id, p_category_id, p_amount, CURRENT_DATE, p_description);

    RAISE NOTICE 'Транзакция успешно добавлена';

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Ошибка: Нарушена целостность данных (FK violation). Проверьте ID пользователя.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Бизнес-ошибка: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- когда добавляется транзакция баланс в таблице users должен меняться
CREATE OR REPLACE FUNCTION trg_update_user_budget()
RETURNS TRIGGER AS $$
DECLARE
    v_type VARCHAR(10);
BEGIN
    SELECT type INTO v_type FROM categories WHERE id = NEW.category_id;

    IF v_type = 'income' THEN
        UPDATE users SET budget = budget + NEW.amount WHERE id = NEW.user_id;
    ELSIF v_type = 'expense' THEN
        IF (SELECT budget - NEW.amount FROM users WHERE id = NEW.user_id) < -5000 THEN
            RAISE EXCEPTION 'Недостаточно средств на бюджете для совершения операции';
        END IF;
        UPDATE users SET budget = budget - NEW.amount WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_after_insert_transaction
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION trg_update_user_budget();


-- аудит при удалении транзакции
CREATE OR REPLACE FUNCTION trg_audit_delete_transaction()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO transactions_audit (transaction_id, user_id, old_amount, description)
    VALUES (OLD.id, OLD.user_id, OLD.amount, OLD.description);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_before_delete_transaction
BEFORE DELETE ON transactions
FOR EACH ROW
EXECUTE FUNCTION trg_audit_delete_transaction();


-- ==========================================

-- проверка цели васи
SELECT name, fn_get_goal_progress(id) as percent_complete 
FROM goals 
WHERE name = 'New phone';


-- триггер на бюджет васи 
SELECT username, budget FROM users WHERE id = 1;
CALL sp_add_transaction(1, 1, 10000, 'Premium bonus');

SELECT username, budget FROM users WHERE id = 1;


-- попытка использовать чужую категорию
CALL sp_add_transaction(2, 1, 500, 'Attempt to steal category');


-- триггер аудита
DELETE FROM transactions WHERE id = (SELECT MAX(id) FROM transactions);
SELECT * FROM transactions_audit;


-- проверка блокировки по бюджету
DO $$
BEGIN
    CALL sp_add_transaction(3, 10, 1000000, 'Buy a masterpiece');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Перехвачено исключение: %', SQLERRM;
END $$;