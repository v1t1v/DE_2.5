CREATE TABLE IF NOT EXISTS sales_statistics (
    shop_name varchar(100),
    product_name varchar(255),
    sales_fact DOUBLE PRECISION,
    sales_plan DOUBLE PRECISION,
    sales_fact_sales_plan DOUBLE PRECISION,
    income_fact DOUBLE PRECISION,
    income_plan DOUBLE PRECISION,
    income_fact_income_plan DOUBLE PRECISION
);

ALTER TABLE shop_dns ADD COLUMN IF NOT EXISTS shop_id int;
ALTER TABLE shop_dns ALTER COLUMN shop_id SET DEFAULT 1;
UPDATE shop_dns SET shop_id = 1;

ALTER TABLE shop_mvideo ADD COLUMN IF NOT EXISTS shop_id int;
ALTER TABLE shop_mvideo ALTER COLUMN shop_id SET DEFAULT 2;
UPDATE shop_mvideo SET shop_id = 2;

ALTER TABLE shop_sitilink ADD COLUMN IF NOT EXISTS shop_id int;
ALTER TABLE shop_sitilink ALTER COLUMN shop_id SET DEFAULT 3;
UPDATE shop_sitilink SET shop_id = 3;

CREATE TEMP TABLE combine_all_sales AS
select * from shop_dns
union
select * from shop_mvideo
UNION
select * from shop_sitilink order by buy_date;

DO $$ 
DECLARE 
    outer_shop_id int;
    outer_shop_name text;
    outer_product_id int;
    outer_product_name text;
    outer_price float;
    outer_sales_plan int;
    due_date date;
    
    counted_sales_fact int;
BEGIN
    FOR outer_shop_id IN SELECT shop_id FROM shops LOOP
        FOR outer_product_id IN SELECT product_id FROM products LOOP
        	select shop_name into outer_shop_name from shops where shop_id = outer_shop_id;
            select product_name into outer_product_name from products where product_id = outer_product_id;
            select price into outer_price from products where product_id = outer_product_id;
            select plan_date into due_date from plan where shop_id = outer_shop_id and product_id = outer_product_id;
            select plan_cnt into outer_sales_plan from plan where shop_id = outer_shop_id and product_id = outer_product_id;
            
            select sum(sales_cnt) as summa into counted_sales_fact from combine_all_sales where shop_id = outer_shop_id and product_id = outer_product_id and buy_date <= due_date;
            
            insert into sales_statistics (shop_name, product_name, sales_fact, sales_plan, sales_fact_sales_plan, income_fact, income_plan, income_fact_income_plan)
            VALUES (outer_shop_name, outer_product_name, counted_sales_fact, outer_sales_plan, counted_sales_fact/outer_sales_plan, outer_price*counted_sales_fact, outer_price*outer_sales_plan, (outer_price*counted_sales_fact)/(outer_price*outer_sales_plan));
        END LOOP;
    END LOOP;
END $$;