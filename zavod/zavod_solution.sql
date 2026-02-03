WITH RECURSIVE

    Unique_Batches AS (
        SELECT DISTINCT
            year,
            plant_id,
            produced_material,
            produced_material_release_type,
            produced_material_production_type,
            produced_material_quantity
        FROM bom_raw
    ),
    Annual_Production AS (
        SELECT
            year,
            plant_id,
            produced_material,
            produced_material_release_type,
            produced_material_production_type,
            SUM(produced_material_quantity) as annual_produced_qty
        FROM Unique_Batches
        GROUP BY year, plant_id, produced_material,
                 produced_material_release_type, produced_material_production_type
    ),

    Annual_Edges AS (
        SELECT
            year,
            plant_id,
            produced_material, -- Родитель
            component_material, -- Ребенок
            component_material_release_type,
            component_material_production_type,
            SUM(component_material_quantity) as annual_component_qty
        FROM bom_raw
        GROUP BY year, plant_id, produced_material,
                 component_material, component_material_release_type,
                 component_material_production_type
    ),

-- 3. Рекурсивное построение дерева
    BoM_Tree AS (
        -- Начальная точка: находим все FIN материалы
        -- Соединяем их с их прямыми компонентами (первый уровень вложенности)
        SELECT
            e.plant_id,
            e.year,

            -- Данные FIN материала
            p.produced_material AS fin_material_id,
            p.produced_material_release_type AS fin_material_release_type,
            p.produced_material_production_type AS fin_material_production_type,
            p.annual_produced_qty AS fin_production_quantity,

            -- Данные PROD материала
            p.produced_material AS prod_material_id,
            p.produced_material_release_type AS prod_material_release_type,
            p.produced_material_production_type AS prod_material_production_type,
            p.annual_produced_qty AS prod_material_production_quantity,

            -- Данные Компонента
            e.component_material AS component_id,
            e.component_material_release_type,
            e.component_material_production_type,
            e.annual_component_qty AS component_consumption_quantity,

            1 AS level -- Уровень вложенности

        FROM Annual_Edges e
                 JOIN Annual_Production p
                      ON e.produced_material = p.produced_material
                          AND e.year = p.year
                          AND e.plant_id = p.plant_id
        WHERE p.produced_material_release_type = 'FIN' -- Начинаем только с FIN

        UNION ALL

        -- === RECURSIVE MEMBER (РЕКУРСИВНАЯ ЧАСТЬ) ===
        -- Ищем компоненты для компонентов предыдущего шага
        SELECT
            child_edge.plant_id,
            child_edge.year,

            -- Данные FIN "протаскиваем" вниз без изменений
            parent_tree.fin_material_id,
            parent_tree.fin_material_release_type,
            parent_tree.fin_material_production_type,
            parent_tree.fin_production_quantity,

            -- НОВЫЙ Родитель - это компонент с предыдущего уровня
            child_prod.produced_material AS prod_material_id,
            child_prod.produced_material_release_type,
            child_prod.produced_material_production_type,
            child_prod.annual_produced_qty,

            -- НОВЫЙ Компонент
            child_edge.component_material AS component_id,
            child_edge.component_material_release_type,
            child_edge.component_material_production_type,
            child_edge.annual_component_qty,

            parent_tree.level + 1

        FROM BoM_Tree parent_tree
                 -- Join 1: Находим, где компонент родителя является производимым материалом (prod)
                 JOIN Annual_Production child_prod
                      ON parent_tree.component_id = child_prod.produced_material
                          AND parent_tree.year = child_prod.year
                          AND parent_tree.plant_id = child_prod.plant_id
            -- Join 2: Находим компоненты этого нового родителя
                 JOIN Annual_Edges child_edge
                      ON child_prod.produced_material = child_edge.produced_material
                          AND child_prod.year = child_edge.year
                          AND child_prod.plant_id = child_edge.plant_id
    )

-- 4. Финальная выборка
SELECT * FROM BoM_Tree
ORDER BY plant_id, year, fin_material_id, level, prod_material_id;