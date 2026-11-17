CREATE OR REPLACE PACKAGE rv_atendimento AUTHID DEFINER AS
    PROCEDURE definir_modo(p_pessoa VARCHAR2, p_ativo CHAR);
    PROCEDURE publicar_pedido(p_autor VARCHAR2, p_titulo VARCHAR2, p_descricao VARCHAR2,
        p_tag VARCHAR2, p_id OUT VARCHAR2, p_centavos NUMBER DEFAULT NULL,
        p_unidade VARCHAR2 DEFAULT NULL, p_foto VARCHAR2 DEFAULT NULL);
    PROCEDURE comentar_pedido(p_pedido VARCHAR2, p_autor VARCHAR2,
        p_texto VARCHAR2, p_indicado VARCHAR2 DEFAULT NULL);
    PROCEDURE abrir_conversa(p_pessoa VARCHAR2, p_contato VARCHAR2,
        p_id OUT NUMBER, p_pedido VARCHAR2 DEFAULT NULL);
    PROCEDURE enviar_mensagem(p_conversa NUMBER, p_autor VARCHAR2, p_texto CLOB);
    PROCEDURE propor_servico(p_conversa NUMBER, p_autor VARCHAR2,
        p_titulo VARCHAR2, p_descricao VARCHAR2,
        p_centavos NUMBER DEFAULT NULL, p_unidade VARCHAR2 DEFAULT NULL);
    PROCEDURE resolver_pedido(p_pedido VARCHAR2, p_autor VARCHAR2);
    PROCEDURE avaliar_atendimento(p_pedido VARCHAR2, p_autor VARCHAR2,
        p_prestador VARCHAR2, p_estrelas NUMBER, p_comentario VARCHAR2 DEFAULT NULL);
END rv_atendimento;
/

CREATE OR REPLACE PACKAGE BODY rv_atendimento AS
    PROCEDURE validar_valor(p_centavos NUMBER, p_unidade VARCHAR2) IS
    BEGIN
        IF p_centavos IS NULL AND p_unidade IS NULL THEN RETURN; END IF;
        IF p_centavos IS NULL OR p_unidade IS NULL OR p_centavos <= 0
           OR p_centavos <> TRUNC(p_centavos) OR p_centavos > 9223372036854775807
           OR p_unidade NOT IN ('service','hour','visit','day','piece') THEN
            raise_application_error(-20101, 'Informe centavos inteiros positivos e uma unidade válida.');
        END IF;
    END;

    FUNCTION preco_legivel(p_centavos NUMBER, p_unidade VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_centavos IS NULL THEN RETURN 'A combinar'; END IF;
        RETURN 'R$ ' || TO_CHAR(p_centavos / 100, 'FM999G999G999G999G999G990D00',
                                'NLS_NUMERIC_CHARACTERS='',.''') || ' ' ||
               CASE p_unidade WHEN 'service' THEN 'pelo serviço' WHEN 'hour' THEN 'por hora'
                   WHEN 'visit' THEN 'por visita' WHEN 'day' THEN 'por diária' ELSE 'por peça' END;
    END;

    PROCEDURE definir_modo(p_pessoa VARCHAR2, p_ativo CHAR) IS
        v_id rv_pessoa.id%TYPE;
        v_tags NUMBER;
        v_bairros NUMBER;
    BEGIN
        SELECT id INTO v_id FROM rv_pessoa WHERE id = p_pessoa FOR UPDATE;
        IF p_ativo IS NULL OR p_ativo NOT IN ('S','N') THEN
            raise_application_error(-20102, 'Escolha ativar ou desativar o perfil profissional.');
        END IF;
        IF p_ativo = 'S' THEN
            SELECT COUNT(*) INTO v_tags FROM rv_especialidade WHERE pessoa_id = p_pessoa;
            SELECT COUNT(*) INTO v_bairros FROM rv_cobertura WHERE pessoa_id = p_pessoa;
            IF v_tags = 0 OR v_bairros = 0 THEN
                raise_application_error(-20102, 'Escolha uma especialidade e um bairro de atendimento.');
            END IF;
        END IF;
        UPDATE rv_pessoa SET profissional = p_ativo WHERE id = p_pessoa;
    END;

    PROCEDURE publicar_pedido(p_autor VARCHAR2, p_titulo VARCHAR2, p_descricao VARCHAR2,
        p_tag VARCHAR2, p_id OUT VARCHAR2, p_centavos NUMBER DEFAULT NULL,
        p_unidade VARCHAR2 DEFAULT NULL, p_foto VARCHAR2 DEFAULT NULL) IS
        v_bairro rv_bairro.id%TYPE;
    BEGIN
        validar_valor(p_centavos, p_unidade);
        IF TRIM(p_titulo) IS NULL OR TRIM(p_descricao) IS NULL OR LENGTH(TRIM(p_descricao)) > 1400 THEN
            raise_application_error(-20103, 'Informe o título e uma descrição de até 1400 caracteres.');
        END IF;
        SELECT bairro_id INTO v_bairro FROM rv_pessoa WHERE id = p_autor;
        p_id := 'p-' || LOWER(RAWTOHEX(SYS_GUID()));
        INSERT INTO rv_pedido (id, autor_id, bairro_id, tag, titulo, descricao, foto, centavos, unidade)
        VALUES (p_id, p_autor, v_bairro, p_tag, TRIM(p_titulo), TRIM(p_descricao), p_foto, p_centavos, p_unidade);
    END;

    PROCEDURE comentar_pedido(p_pedido VARCHAR2, p_autor VARCHAR2,
        p_texto VARCHAR2, p_indicado VARCHAR2 DEFAULT NULL) IS
        v_ativo rv_pessoa.profissional%TYPE;
    BEGIN
        IF TRIM(p_texto) IS NULL THEN raise_application_error(-20104, 'Escreva um comentário.'); END IF;
        IF p_indicado IS NOT NULL THEN
            SELECT profissional INTO v_ativo FROM rv_pessoa WHERE id = p_indicado;
            IF v_ativo <> 'S' THEN raise_application_error(-20104, 'Indique um prestador ativo.'); END IF;
        END IF;
        INSERT INTO rv_comentario (pedido_id, autor_id, indicado_id, texto)
        VALUES (p_pedido, p_autor, p_indicado, TRIM(p_texto));
    END;

    PROCEDURE abrir_conversa(p_pessoa VARCHAR2, p_contato VARCHAR2,
        p_id OUT NUMBER, p_pedido VARCHAR2 DEFAULT NULL) IS
        v_a rv_pessoa.id%TYPE := LEAST(p_pessoa, p_contato);
        v_b rv_pessoa.id%TYPE := GREATEST(p_pessoa, p_contato);
        v_dono rv_pessoa.id%TYPE;
    BEGIN
        IF v_a IS NULL OR v_a = v_b THEN
            raise_application_error(-20105, 'Escolha dois participantes diferentes.');
        END IF;
        IF p_pedido IS NOT NULL THEN
            SELECT autor_id INTO v_dono FROM rv_pedido WHERE id = p_pedido;
            IF v_dono NOT IN (v_a,v_b) THEN
                raise_application_error(-20105, 'O autor do pedido precisa participar da conversa.');
            END IF;
        END IF;
        BEGIN
            INSERT INTO rv_conversa (pessoa_a, pessoa_b, pedido_id) VALUES (v_a, v_b, p_pedido)
            RETURNING id INTO p_id;
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
            SELECT id INTO p_id FROM rv_conversa WHERE pessoa_a = v_a AND pessoa_b = v_b
              AND (pedido_id = p_pedido OR (pedido_id IS NULL AND p_pedido IS NULL));
        END;
    END;

    PROCEDURE validar_participante(p_conversa NUMBER, p_autor VARCHAR2) IS
        v_id NUMBER;
    BEGIN
        SELECT id INTO v_id FROM rv_conversa
         WHERE id = p_conversa AND p_autor IN (pessoa_a, pessoa_b) FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        raise_application_error(-20106, 'Esta conversa não pertence ao participante informado.');
    END;

    PROCEDURE enviar_mensagem(p_conversa NUMBER, p_autor VARCHAR2, p_texto CLOB) IS
        v_texto CLOB := TRIM(p_texto);
    BEGIN
        validar_participante(p_conversa, p_autor);
        IF v_texto IS NULL OR DBMS_LOB.GETLENGTH(v_texto) = 0 THEN
            raise_application_error(-20107, 'Escreva uma mensagem.');
        END IF;
        INSERT INTO rv_mensagem (conversa_id, autor_id, tipo, texto)
        VALUES (p_conversa, p_autor, 'texto', v_texto);
    END;

    PROCEDURE propor_servico(p_conversa NUMBER, p_autor VARCHAR2,
        p_titulo VARCHAR2, p_descricao VARCHAR2,
        p_centavos NUMBER DEFAULT NULL, p_unidade VARCHAR2 DEFAULT NULL) IS
        v_antes rv_resumo_conversa%ROWTYPE;
        v_titulo rv_mensagem.titulo%TYPE := TRIM(p_titulo);
        v_descricao CLOB := TRIM(p_descricao);
        v_texto CLOB;
        v_mesmo_servico BOOLEAN;
        v_mesmo_preco BOOLEAN;
    BEGIN
        validar_valor(p_centavos, p_unidade);
        IF v_titulo IS NULL OR LENGTH(TRIM(p_descricao)) > 1400 THEN
            raise_application_error(-20103, 'Informe o serviço e use até 1400 caracteres na descrição.');
        END IF;
        validar_participante(p_conversa, p_autor);
        SELECT * INTO v_antes FROM rv_resumo_conversa WHERE conversa_id = p_conversa;
        v_mesmo_servico := v_antes.titulo IS NOT NULL AND v_antes.titulo = v_titulo
          AND ((v_antes.descricao IS NULL AND v_descricao IS NULL)
               OR NVL(DBMS_LOB.COMPARE(v_antes.descricao, v_descricao), -1) = 0);
        v_mesmo_preco := NVL(v_antes.centavos, -1) = NVL(p_centavos, -1)
                     AND NVL(v_antes.unidade, '-') = NVL(p_unidade, '-');
        IF v_mesmo_servico AND v_mesmo_preco THEN RETURN; END IF;
        IF NOT v_mesmo_servico THEN
            v_texto := 'Serviço: ' || v_titulo;
            IF v_descricao IS NOT NULL THEN v_texto := v_texto || CHR(10) || v_descricao; END IF;
        END IF;
        IF NOT v_mesmo_preco THEN
            IF v_texto IS NOT NULL THEN v_texto := v_texto || CHR(10); END IF;
            IF p_centavos IS NULL THEN
                v_texto := v_texto || 'Prefiro combinar o valor por aqui.';
            ELSE
                v_texto := v_texto || 'Proponho ' || preco_legivel(p_centavos, p_unidade) || '.';
            END IF;
            IF v_antes.centavos IS NOT NULL THEN
                v_texto := v_texto || CHR(10) || 'Estimativa anterior: ' ||
                           preco_legivel(v_antes.centavos, v_antes.unidade) || '.';
            END IF;
        END IF;
        INSERT INTO rv_mensagem (conversa_id, autor_id, tipo, texto, titulo, descricao, centavos, unidade)
        VALUES (p_conversa, p_autor, 'proposta', v_texto, v_titulo, v_descricao, p_centavos, p_unidade);
    END;

    PROCEDURE resolver_pedido(p_pedido VARCHAR2, p_autor VARCHAR2) IS
    BEGIN
        UPDATE rv_pedido SET resolvido_em = COALESCE(resolvido_em, SYSTIMESTAMP)
         WHERE id = p_pedido AND autor_id = p_autor;
        IF SQL%ROWCOUNT = 0 THEN raise_application_error(-20108, 'Somente o autor pode resolver o pedido.'); END IF;
    END;

    PROCEDURE avaliar_atendimento(p_pedido VARCHAR2, p_autor VARCHAR2,
        p_prestador VARCHAR2, p_estrelas NUMBER, p_comentario VARCHAR2 DEFAULT NULL) IS
        v_dono rv_pedido.autor_id%TYPE;
        v_fim rv_pedido.resolvido_em%TYPE;
    BEGIN
        SELECT autor_id, resolvido_em INTO v_dono, v_fim FROM rv_pedido WHERE id = p_pedido FOR UPDATE;
        IF p_autor IS NULL OR p_autor <> v_dono OR v_fim IS NULL OR p_prestador IS NULL OR p_prestador = v_dono
           OR p_estrelas IS NULL OR p_estrelas <> TRUNC(p_estrelas) OR p_estrelas NOT BETWEEN 1 AND 5 THEN
            raise_application_error(-20109, 'O autor pode avaliar outro morador após a resolução, com nota de 1 a 5.');
        END IF;
        INSERT INTO rv_avaliacao (pedido_id, prestador_id, estrelas, comentario)
        VALUES (p_pedido, p_prestador, p_estrelas, TRIM(p_comentario));
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
        raise_application_error(-20110, 'Este pedido já foi avaliado.');
    END;
END rv_atendimento;
/
