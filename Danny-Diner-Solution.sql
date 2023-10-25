-- Case Study 1 Danny's Dinner
USE Danny_Diner;

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
Select 
    s.customer_id,
    sum(mn.price) as Total_Amount_Spent,
    count (distinct order_date) as Days_Visited
from sales s 
left join menu mn
on s.product_id=mn.product_id
group by s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT 
    customer_id,
    product_name as first_product_by_customer
FROM(
    select
    s.customer_id,
    mn.product_name,
    Dense_rank() over (partition by s.customer_id order by s.order_date) as row_number
    from sales s 
    left join menu mn
    on s.product_id=mn.product_id
    ) n
where row_number=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    TOP 1
    mn.product_name,
    count(s.product_id) as sales_count
from sales s
left join menu mn
on s.product_id=mn.product_id
group by mn.product_name
order by sales_count desc;

-- 5. Which item was the most popular for each customer?
SELECT
    customer_id,
    product_name as most_ordered
FROM(
    Select
        s.customer_id,
        mn.product_name,
        count(s.product_id) as sales_count,
        Dense_rank() over (partition by s.customer_id order by count(s.product_id) desc) as row_number
    from sales s
    left join menu mn
    on s.product_id=mn.product_id
    group by 
        s.customer_id,
        mn.product_name
    ) n
where row_number =1;

-- 6. Which item was purchased first by the customer after they became a member
SELECT
    n.customer_id,
    mn.product_name as first_product_after_membership
FROM
    (select 
        s.customer_id,
        s.order_date,
        s.product_id,
        Dense_rank() OVER (partition by s.customer_id order by s.order_date) as row_number
    FROM sales s
    join members m 
    on s.customer_id=m.customer_id 
        AND s.order_date>=m.join_date   -- keep the records after membership
        ) n
join menu mn 
on n.product_id=mn.product_id
where n.row_number=1;

-- 7. Which item was purchased just before the customer became a member?
SELECT
    n.customer_id,
    mn.product_name as last_product_before_membership
FROM
    (select 
        s.customer_id,
        s.order_date,
        s.product_id,
        Dense_rank() OVER (partition by s.customer_id order by s.order_date desc) as row_number
    FROM sales s
    join members m 
    on s.customer_id=m.customer_id 
        AND s.order_date<m.join_date    -- keep the records before membership
        ) n
join menu mn 
on n.product_id=mn.product_id
where n.row_number=1;

-- 8. What is the total items and amount spent for each member before they became a member?
select 
        s.customer_id,
        count(s.product_id) as total_products_before_membership,
        sum(mn.price) as total_amount_spent_before_customer
FROM sales s
join members m 
on s.customer_id=m.customer_id 
AND s.order_date<m.join_date    -- keep the records before membership
join menu mn 
on s.product_id=mn.product_id
group by s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2* points multiplier - how many points would each customer have?
SELECT
    customer_id,
    sum(points) as total_points
FROM
    (SELECT
        s.customer_id,
        case
        when mn.product_name = 'sushi' then mn.price*20
        else mn.price*10
        end as points
    FROM sales s
    join menu mn
    on s.product_id=mn.product_id) p
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2* points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
SELECT
    customer_id,
    sum(points) as total_points_new
FROM
    (SELECT
      s.customer_id,
      s.order_date,
      CASE 
      when s.order_date >=m.join_date and s.order_date < dateadd(day,7,join_date) then mn.price*20
      when mn.product_name='sushi' then mn.price*20
      else mn.price*10
      end as points
    FROM sales s
    join menu mn
    on s.product_id=mn.product_id
    join members m
    on s.customer_id=m.customer_id
    ) p
WHERE order_date < CAST('2021-02-01' as date) 
group by customer_id;

-- Bonus Question 1: Join All The Things
SELECT 
    s.customer_id,
    s.order_date,
    mn.product_name,
    mn.price,
    case when m.join_date is null then 'N'
    when s.order_date < m.join_date then 'N'
    else 'Y'
    end as member
FROM sales s
left join members m
on s.customer_id=m.customer_id
left join menu mn
on s.product_id=mn.product_id;

-- Bonus Question 2: Rank All The Things
With CTE AS (SELECT 
    s.customer_id,
    s.order_date,
    mn.product_name,
    mn.price,
    case when m.join_date is null then 'N'
    when s.order_date < m.join_date then 'N'
    else 'Y'
    end as member
FROM sales s
left join members m
on s.customer_id=m.customer_id
left join menu mn
on s.product_id=mn.product_id)

SELECT
    *,
    DENSE_RANK() over (partition by customer_id order by order_date) as ranking
FROM CTE
where member ='Y'
union all
select
    *,
    null as ranking
from CTE
where member = 'N'
order by customer_id, order_date;