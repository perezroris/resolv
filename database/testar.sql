WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET DEFINE OFF
SET SERVEROUTPUT ON
DECLARE
    v_sufixo VARCHAR2(32) := LOWER(RAWTOHEX(SYS_GUID()));
    v_morador VARCHAR2(80) := 'mor-' || v_sufixo;
    v_lia VARCHAR2(80) := 'lia-' || v_sufixo;
    v_outro VARCHAR2(80) := 'out-' || v_sufixo;
    v_pedido VARCHAR2(80);
    v_duvida VARCHAR2(80);
    v_chat NUMBER;
    v_segundo NUMBER;
    v_direto NUMBER;
    v_reaberto NUMBER;
    v_n NUMBER;
    v_preco NUMBER;
    v_anterior VARCHAR2(200);
    v_resumo rv_resumo_conversa%ROWTYPE;

    PROCEDURE falhou(p_texto VARCHAR2) IS
    BEGIN
        raise_application_error(-20990, p_texto);
    END;
    PROCEDURE conferir(p_condicao BOOLEAN, p_texto VARCHAR2) IS
    BEGIN
        IF p_condicao IS NULL OR NOT p_condicao THEN falhou(p_texto); END IF;
    END;
BEGIN
    SAVEPOINT rv_inicio_teste;
    INSERT INTO rv_pessoa (id, nome, bairro_id) VALUES (v_morador, 'Morador do teste', 1);
    INSERT INTO rv_pessoa (id, nome, bairro_id) VALUES (v_lia, 'Lia do teste', 2);
    INSERT INTO rv_pessoa (id, nome, bairro_id) VALUES (v_outro, 'Outro morador do teste', 3);

    BEGIN
        rv_atendimento.definir_modo(v_lia, 'S');
        falhou('Ativou sem cobertura e tags.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20102 THEN RAISE; END IF;
    END;
    INSERT INTO rv_especialidade VALUES (v_lia, 'costura');
    BEGIN
        rv_atendimento.definir_modo(v_lia, 'S');
        falhou('Ativou sem cobertura.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20102 THEN RAISE; END IF;
    END;
    BEGIN
        INSERT INTO rv_especialidade VALUES (v_lia, 'orientacao');
        falhou('Orientação virou especialidade.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -2290 THEN RAISE; END IF;
    END;
    INSERT INTO rv_cobertura VALUES (v_lia, 1);
    rv_atendimento.definir_modo(v_lia, 'S');
    rv_atendimento.publicar_pedido(v_morador, 'Barra de duas calças', 'Ajustar a barra reta.', 'costura',
                                   v_pedido, 3500, 'piece');
    rv_atendimento.publicar_pedido(v_morador, 'Quem pode ajudar?', 'Preciso identificar a peça.', 'orientacao', v_duvida);
    UPDATE rv_pessoa SET bairro_id = 3 WHERE id = v_morador;
    SELECT COUNT(*) INTO v_n FROM rv_servicos_compativeis WHERE profissional_id = v_lia AND pedido_id = v_pedido;
    conferir(v_n = 1, 'O pedido deve continuar no bairro de publicação.');
    SELECT COUNT(*) INTO v_n FROM rv_servicos_compativeis WHERE pedido_id = v_duvida;
    conferir(v_n = 0, 'Orientação não tem especialidade correspondente.');
    rv_atendimento.definir_modo(v_lia, 'N');
    SELECT COUNT(*) INTO v_n FROM rv_servicos_compativeis WHERE profissional_id = v_lia;
    conferir(v_n = 0, 'O modo desativado ainda exibe serviços.');
    rv_atendimento.definir_modo(v_lia, 'S');
    DBMS_OUTPUT.PUT_LINE('OK 1. Perfil único, cobertura, tag e bairro original do pedido.');

    rv_atendimento.comentar_pedido(v_pedido, v_outro, 'A Lia faz esse ajuste.', v_lia);
    SELECT COUNT(*) INTO v_n FROM rv_comentario WHERE pedido_id = v_pedido AND indicado_id = v_lia;
    conferir(v_n = 1, 'Faltou a indicação no comentário.');
    BEGIN
        rv_atendimento.comentar_pedido(v_pedido, v_morador, 'Indicação', v_outro);
        falhou('Indicou morador inativo.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20104 THEN RAISE; END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('OK 2. Indicação de profissional no comentário.');

    rv_atendimento.abrir_conversa(v_morador, v_lia, v_chat, v_pedido);
    rv_atendimento.abrir_conversa(v_lia, v_morador, v_reaberto, v_pedido);
    conferir(v_reaberto = v_chat, 'Duplicou o chat do pedido ao inverter a ordem.');
    rv_atendimento.abrir_conversa(v_lia, v_morador, v_direto);
    rv_atendimento.abrir_conversa(v_morador, v_lia, v_reaberto);
    conferir(v_direto = v_reaberto AND v_direto <> v_chat, 'Duplicou ou misturou chats diretos.');
    rv_atendimento.abrir_conversa(v_morador, v_outro, v_segundo, v_pedido);
    BEGIN
        rv_atendimento.abrir_conversa(v_lia, v_outro, v_reaberto, v_pedido);
        falhou('Abriu chat sem o dono do pedido.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20105 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.enviar_mensagem(v_chat, v_outro, 'Oi');
        falhou('Uma terceira pessoa escreveu no chat.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20106 THEN RAISE; END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('OK 3. Chat direto, chat do pedido e autoria de mensagens.');

    SELECT * INTO v_resumo FROM rv_resumo_conversa WHERE conversa_id = v_chat;
    conferir(v_resumo.centavos = 3500 AND v_resumo.unidade = 'piece' AND v_resumo.proposta_id IS NULL,
             'O orçamento original não chegou ao chat.');
    rv_atendimento.propor_servico(v_chat, v_lia, 'Barra de duas calças', 'Ajustar a barra reta.', 3000, 'piece');
    rv_atendimento.propor_servico(v_chat, v_lia, 'Barra de duas calças', 'Ajustar a barra reta.', 3000, 'piece');
    rv_atendimento.enviar_mensagem(v_chat, v_morador, 'Posso levar às 15h?');
    SELECT * INTO v_resumo FROM rv_resumo_conversa WHERE conversa_id = v_chat;
    conferir(v_resumo.centavos = 3000 AND v_resumo.unidade = 'piece', 'Mensagem comum mudou o preço.');
    SELECT COUNT(*) INTO v_n FROM rv_mensagem WHERE conversa_id = v_chat AND tipo = 'proposta';
    conferir(v_n = 1, 'Reenviar a mesma proposta duplicou o histórico.');
    SELECT DBMS_LOB.SUBSTR(texto, 200, 1) INTO v_anterior FROM rv_mensagem WHERE id = v_resumo.proposta_id;
    conferir(INSTR(v_anterior, 'Estimativa anterior: R$ 35,00 por peça.') > 0, 'Perdeu o valor anterior.');
    SELECT centavos INTO v_preco FROM rv_resumo_conversa WHERE conversa_id = v_segundo;
    conferir(v_preco = 3500, 'Alterou o resumo do outro contato.');
    rv_atendimento.propor_servico(v_chat, v_morador, 'Barra de duas calças', 'Ajustar a barra reta.');
    SELECT * INTO v_resumo FROM rv_resumo_conversa WHERE conversa_id = v_chat;
    conferir(v_resumo.centavos IS NULL AND v_resumo.unidade IS NULL AND v_resumo.proposta_id IS NOT NULL,
             'A combinar recuperou o valor do pedido por engano.');
    SELECT centavos INTO v_preco FROM rv_pedido WHERE id = v_pedido;
    conferir(v_preco = 3500, 'A proposta privada modificou o Mural.');
    DBMS_OUTPUT.PUT_LINE('OK 4. Contraproposta, histórico e volta a A combinar.');

    rv_atendimento.propor_servico(v_direto, v_morador, 'Pequeno ajuste', NULL, 12050, 'service');
    rv_atendimento.propor_servico(v_direto, v_lia, 'Pequeno ajuste', NULL, 12050, 'hour');
    SELECT * INTO v_resumo FROM rv_resumo_conversa WHERE conversa_id = v_direto;
    conferir(v_resumo.titulo = 'Pequeno ajuste' AND v_resumo.unidade = 'hour', 'Ignorou a troca de unidade.');
    BEGIN
        rv_atendimento.propor_servico(v_direto, v_lia, 'Ajuste', NULL, 0, 'hour');
        falhou('Aceitou preço zero.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20101 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.propor_servico(v_direto, v_lia, 'Ajuste', NULL, 3000, NULL);
        falhou('Aceitou preço sem unidade.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20101 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.propor_servico(v_direto, v_lia, 'Ajuste', NULL, NULL, 'day');
        falhou('Aceitou unidade sem preço.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20101 THEN RAISE; END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('OK 5. Serviço da Vitrine, troca de unidade e validação de valores.');

    BEGIN
        rv_atendimento.avaliar_atendimento(v_pedido, v_morador, v_lia, 5);
        falhou('Avaliou pedido aberto.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20109 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.resolver_pedido(v_pedido, v_lia);
        falhou('Um terceiro encerrou o pedido.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20108 THEN RAISE; END IF;
    END;
    rv_atendimento.resolver_pedido(v_pedido, v_morador);
    SELECT COUNT(*) INTO v_n FROM rv_servicos_compativeis WHERE pedido_id = v_pedido;
    conferir(v_n = 0, 'Pedido resolvido continua na lista de serviços.');
    BEGIN
        rv_atendimento.avaliar_atendimento(v_pedido, v_morador, v_morador, 5);
        falhou('Aceitou autoavaliação.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20109 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.avaliar_atendimento(v_pedido, v_outro, v_lia, 5);
        falhou('A avaliação não é do autor.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20109 THEN RAISE; END IF;
    END;
    BEGIN
        rv_atendimento.avaliar_atendimento(v_pedido, v_morador, v_lia, 4.5);
        falhou('Aceitou meia estrela.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20109 THEN RAISE; END IF;
    END;
    rv_atendimento.avaliar_atendimento(v_pedido, v_morador, v_lia, 5, 'As duas barras ficaram boas.');
    BEGIN
        rv_atendimento.avaliar_atendimento(v_pedido, v_morador, v_lia, 4);
        falhou('Aceitou uma segunda avaliação.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20110 THEN RAISE; END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('OK 6. Resolução e avaliação única pelo autor.');
    ROLLBACK TO rv_inicio_teste;
    DBMS_OUTPUT.PUT_LINE('Teste concluído. Os dados fictícios desta execução foram desfeitos.');
EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO rv_inicio_teste;
    RAISE;
END;
/
