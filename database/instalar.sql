WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET DEFINE OFF
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON
PROMPT Criando as tabelas e consultas do resolv!
@@01_estrutura.sql
@@02_catalogo.sql
@@03_rotinas.sql
SHOW ERRORS PACKAGE rv_atendimento
SHOW ERRORS PACKAGE BODY rv_atendimento
DECLARE
    v_invalidos NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_invalidos FROM user_objects
     WHERE object_name IN ('RV_ATENDIMENTO','RV_RESUMO_CONVERSA','RV_SERVICOS_COMPATIVEIS') AND status <> 'VALID';
    IF v_invalidos > 0 THEN raise_application_error(-20199, 'Verifique os erros de compilação.'); END IF;
END;
/
COMMIT;
PROMPT Estrutura e rotinas disponíveis.
