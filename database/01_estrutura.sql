CREATE TABLE IF NOT EXISTS rv_bairro (
    id NUMBER PRIMARY KEY,
    nome VARCHAR2(60 CHAR) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS rv_vizinhanca (
    bairro_a NUMBER REFERENCES rv_bairro(id),
    bairro_b NUMBER REFERENCES rv_bairro(id),
    PRIMARY KEY (bairro_a, bairro_b),
    CHECK (bairro_a < bairro_b)
);

CREATE TABLE IF NOT EXISTS rv_tag (
    codigo VARCHAR2(32 CHAR) PRIMARY KEY,
    nome VARCHAR2(60 CHAR) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS rv_pessoa (
    id VARCHAR2(80 CHAR) PRIMARY KEY,
    nome VARCHAR2(80 CHAR) NOT NULL,
    bairro_id NUMBER NOT NULL REFERENCES rv_bairro(id),
    bio VARCHAR2(800 CHAR),
    foto VARCHAR2(500 CHAR),
    profissional CHAR(1) DEFAULT 'N' NOT NULL CHECK (profissional IN ('S','N'))
);

CREATE TABLE IF NOT EXISTS rv_especialidade (
    pessoa_id VARCHAR2(80 CHAR) REFERENCES rv_pessoa(id),
    tag VARCHAR2(32 CHAR) REFERENCES rv_tag(codigo),
    PRIMARY KEY (pessoa_id, tag),
    CHECK (tag <> 'orientacao')
);

CREATE TABLE IF NOT EXISTS rv_cobertura (
    pessoa_id VARCHAR2(80 CHAR) REFERENCES rv_pessoa(id),
    bairro_id NUMBER REFERENCES rv_bairro(id),
    PRIMARY KEY (pessoa_id, bairro_id)
);

CREATE TABLE IF NOT EXISTS rv_pedido (
    id VARCHAR2(80 CHAR) PRIMARY KEY,
    autor_id VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    bairro_id NUMBER NOT NULL REFERENCES rv_bairro(id),
    tag VARCHAR2(32 CHAR) NOT NULL REFERENCES rv_tag(codigo),
    titulo VARCHAR2(100 CHAR) NOT NULL,
    descricao CLOB,
    foto VARCHAR2(500 CHAR),
    centavos NUMBER,
    unidade VARCHAR2(7 CHAR),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
    resolvido_em TIMESTAMP WITH TIME ZONE,
    CONSTRAINT rv_pedido_preco_ck CHECK (
        (centavos IS NULL AND unidade IS NULL) OR
        (centavos IS NOT NULL AND centavos = TRUNC(centavos) AND centavos > 0
         AND unidade IS NOT NULL AND unidade IN ('service','hour','visit','day','piece'))
    )
);

CREATE TABLE IF NOT EXISTS rv_comentario (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pedido(id),
    autor_id VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    indicado_id VARCHAR2(80 CHAR) REFERENCES rv_pessoa(id),
    texto VARCHAR2(600 CHAR) NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS rv_conversa (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id VARCHAR2(80 CHAR) REFERENCES rv_pedido(id),
    pessoa_a VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    pessoa_b VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    CHECK (pessoa_a < pessoa_b),
    CONSTRAINT rv_conversa_par_uk UNIQUE (pessoa_a, pessoa_b, pedido_id)
);

CREATE TABLE IF NOT EXISTS rv_mensagem (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversa_id NUMBER NOT NULL REFERENCES rv_conversa(id),
    autor_id VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    tipo VARCHAR2(8 CHAR) NOT NULL CHECK (tipo IN ('texto','proposta')),
    texto CLOB NOT NULL,
    titulo VARCHAR2(100 CHAR),
    descricao CLOB,
    centavos NUMBER,
    unidade VARCHAR2(7 CHAR),
    exemplo CHAR(1) DEFAULT 'N' NOT NULL CHECK (exemplo IN ('S','N')),
    enviada_em TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
    lida_em TIMESTAMP WITH TIME ZONE,
    CONSTRAINT rv_mensagem_tipo_ck CHECK (
        (tipo = 'texto' AND titulo IS NULL AND centavos IS NULL) OR
        (tipo = 'proposta' AND titulo IS NOT NULL)
    ),
    CONSTRAINT rv_mensagem_preco_ck CHECK (
        (centavos IS NULL AND unidade IS NULL) OR
        (centavos IS NOT NULL AND centavos = TRUNC(centavos) AND centavos > 0
         AND unidade IS NOT NULL AND unidade IN ('service','hour','visit','day','piece'))
    )
);

CREATE INDEX IF NOT EXISTS rv_msg_conversa_ix ON rv_mensagem (conversa_id, tipo, id DESC);

CREATE TABLE IF NOT EXISTS rv_avaliacao (
    pedido_id VARCHAR2(80 CHAR) PRIMARY KEY REFERENCES rv_pedido(id),
    prestador_id VARCHAR2(80 CHAR) NOT NULL REFERENCES rv_pessoa(id),
    estrelas NUMBER NOT NULL CHECK (estrelas = TRUNC(estrelas) AND estrelas BETWEEN 1 AND 5),
    comentario VARCHAR2(240 CHAR),
    criada_em TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE OR REPLACE VIEW rv_servicos_compativeis AS
SELECT e.pessoa_id AS profissional_id, p.id AS pedido_id
  FROM rv_pedido p
  JOIN rv_especialidade e ON e.tag = p.tag
  JOIN rv_cobertura c ON c.pessoa_id = e.pessoa_id AND c.bairro_id = p.bairro_id
  JOIN rv_pessoa mor ON mor.id = e.pessoa_id
 WHERE mor.profissional = 'S' AND p.resolvido_em IS NULL AND p.autor_id <> mor.id;

-- Uma proposta sem preço significa "A combinar". Só usamos o preço do Mural antes da primeira proposta.
CREATE OR REPLACE VIEW rv_resumo_conversa AS
SELECT c.id AS conversa_id, c.pedido_id, m.id AS proposta_id,
       CASE WHEN m.id IS NULL THEN p.titulo ELSE m.titulo END AS titulo,
       CASE WHEN m.id IS NULL THEN p.descricao ELSE m.descricao END AS descricao,
       CASE WHEN m.id IS NULL THEN p.centavos ELSE m.centavos END AS centavos,
       CASE WHEN m.id IS NULL THEN p.unidade ELSE m.unidade END AS unidade
  FROM rv_conversa c
  LEFT JOIN rv_pedido p ON p.id = c.pedido_id
  OUTER APPLY (
      SELECT msg.id, msg.titulo, msg.descricao, msg.centavos, msg.unidade
        FROM rv_mensagem msg WHERE msg.conversa_id = c.id AND msg.tipo = 'proposta'
       ORDER BY msg.id DESC FETCH FIRST 1 ROW ONLY
  ) m;
