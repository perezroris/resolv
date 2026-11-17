MERGE INTO rv_bairro d
USING (
    SELECT 1 AS id, 'Centro' AS nome FROM dual
    UNION ALL SELECT 2, 'Jardim das Flores' FROM dual
    UNION ALL SELECT 3, 'Vila Nova' FROM dual
    UNION ALL SELECT 4, 'Bela Vista' FROM dual
    UNION ALL SELECT 5, 'Santa Clara' FROM dual
    UNION ALL SELECT 6, 'Vila Esperança' FROM dual
    UNION ALL SELECT 7, 'Jardim Primavera' FROM dual
    UNION ALL SELECT 8, 'Parque do Sol' FROM dual
) s ON (d.id = s.id)
WHEN NOT MATCHED THEN INSERT (id, nome) VALUES (s.id, s.nome);

MERGE INTO rv_vizinhanca d
USING (
    SELECT 1 AS bairro_a, 2 AS bairro_b FROM dual
    UNION ALL SELECT 1, 3 FROM dual
    UNION ALL SELECT 2, 4 FROM dual
    UNION ALL SELECT 2, 5 FROM dual
    UNION ALL SELECT 3, 5 FROM dual
    UNION ALL SELECT 3, 6 FROM dual
    UNION ALL SELECT 4, 7 FROM dual
    UNION ALL SELECT 5, 7 FROM dual
    UNION ALL SELECT 6, 8 FROM dual
    UNION ALL SELECT 7, 8 FROM dual
) s ON (d.bairro_a = s.bairro_a AND d.bairro_b = s.bairro_b)
WHEN NOT MATCHED THEN INSERT (bairro_a, bairro_b) VALUES (s.bairro_a, s.bairro_b);

MERGE INTO rv_tag d
USING (
    SELECT 'hidraulica' AS codigo, 'Hidráulica' AS nome FROM dual
    UNION ALL SELECT 'eletrica', 'Elétrica' FROM dual
    UNION ALL SELECT 'limpeza', 'Limpeza' FROM dual
    UNION ALL SELECT 'pintura', 'Pintura' FROM dual
    UNION ALL SELECT 'montagem', 'Montagem de móveis' FROM dual
    UNION ALL SELECT 'reparos', 'Pequenos reparos' FROM dual
    UNION ALL SELECT 'jardinagem', 'Jardinagem' FROM dual
    UNION ALL SELECT 'costura', 'Costura' FROM dual
    UNION ALL SELECT 'aulas', 'Aulas particulares' FROM dual
    UNION ALL SELECT 'informatica', 'Informática' FROM dual
    UNION ALL SELECT 'pets', 'Cuidados com pets' FROM dual
    UNION ALL SELECT 'eletrodomesticos', 'Conserto de eletrodomésticos' FROM dual
    UNION ALL SELECT 'fretes', 'Fretes e mudanças' FROM dual
    UNION ALL SELECT 'beleza', 'Beleza' FROM dual
    UNION ALL SELECT 'fotografia', 'Fotografia' FROM dual
    UNION ALL SELECT 'culinaria', 'Culinária' FROM dual
    UNION ALL SELECT 'orientacao', 'Preciso de orientação' FROM dual
) s ON (d.codigo = s.codigo)
WHEN NOT MATCHED THEN INSERT (codigo, nome) VALUES (s.codigo, s.nome);
