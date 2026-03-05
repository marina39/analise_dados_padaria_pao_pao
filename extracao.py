from config import get_engine
from dotenv import load_dotenv
import pandas as pd
import requests
import os
import io

# --- CONFIGURAÇÃO DE CAMINHOS ---
pasta_entrada = 'entrada'
load_dotenv()

# --- 1. EXTRAÇÃO DO MENU (CSV) ---
caminho_menu = os.path.join(pasta_entrada, 'menu.csv')
df_menu = pd.read_csv(caminho_menu, sep=';')

# Transformar o preço de centavos para reais
df_menu['ITEM_PRECO_REAIS'] = df_menu['ITEM_PRECO_CENTS'] / 100

df_menu = df_menu.rename(columns={
    'ITEM_ID': 'produto_id',
    'ITEM_NOME': 'produto_nome',
    'ITEM_PRECO_REAIS': 'preco_reais'
})

# Limpeza e tipagem da coluna produto_nome
df_menu['produto_nome'] = df_menu['produto_nome'].astype(str).str.strip()

# Remoção de duplicatas
df_menu = (
    df_menu
    .drop_duplicates(subset=['produto_id'])
    .reset_index(drop=True)
)

# Ordenação das colunas e exclusão de ITEM_PRECO_CENTS
df_menu = df_menu[[
    'produto_id', 
    'produto_nome', 
    'preco_reais'
    ]]

# Tipagem
if df_menu['produto_id'].isna().any():
    raise ValueError('Menu com produto_id nulo')
else:
    df_menu['produto_id'] = df_menu['produto_id'].astype(int)

df_menu['preco_reais'] = df_menu['preco_reais'].astype(float)

# Exibição no terminal para conferência
# print('DADOS DE CLIENTES CARREGADOS:')
# print(df_menu.head())


# 2 --- EXTRAÇÃO DE CLIENTES (JSON) ---
url_clientes = os.getenv('URL_CLIENTES')
response_clientes = requests.get(url_clientes)
response_clientes.raise_for_status()

df_clientes = pd.read_json(io.BytesIO(response_clientes.content))
print('Dados de clientes extraídos via HTTP com sucesso!')

# Renomeação das colunas
df_clientes = df_clientes.rename(columns={
    'id': 'cliente_id',
    'nome': 'cliente_nome'
})

# Limpeza e tipagem de cliente_nome
df_clientes['cliente_nome'] = (
    df_clientes['cliente_nome']
    .astype(str)
    .str.strip()
    .replace({'': None, 'None': None})
)

# Remoção de duplicatas
df_clientes = (
    df_clientes
    .drop_duplicates(subset=['cliente_id'])
    .reset_index(drop=True)
)

# Tratamento de data e tipagem de dt_delete
df_clientes['dt_delete'] = pd.to_datetime(df_clientes['dt_delete'], errors='coerce')\
    .dt.tz_localize(None)

inconsistentes = (df_clientes['deletado'] == 0) & df_clientes['dt_delete'].notna()

if inconsistentes.any():
    raise ValueError('Clientes ativos com dt_delete preenchido.')

# Tipagem
if df_clientes['cliente_id'].isna().any():
    raise ValueError('Clientes com cliente_id nulo')
else:
    df_clientes['cliente_id'] = df_clientes['cliente_id'].astype(int)

if not df_clientes['deletado'].isin([0, 1]).all():
    raise ValueError('Campo deletado fora do padrão 0/1')
else:
    df_clientes['deletado'] = df_clientes['deletado'].astype(bool)

# Exibição no terminal para conferência
# print('DADOS DE CLIENTES CARREGADOS:')
# print(df_clientes.head())

# 3 --- EXTRAÇÃO DE MEMBROS (JSON) ---
url_mebros = os.getenv('URL_MEMBROS')
response_membros = requests.get(url_mebros)
response_membros.raise_for_status()

df_membros = pd.read_json(io.BytesIO(response_membros.content))
print('Dados de membros extraídos via HTTP com sucesso!')

# Renomeação das colunas
df_membros = df_membros.rename(columns={
    'id': 'membro_id'
})

# Remoção de duplicatas
df_membros = (
    df_membros
    .drop_duplicates(subset=['membro_id'])
    .reset_index(drop=True)
)

# Tratamento e tipagem de datas
colunas_datas = ['dt_inicio_assinatura', 'dt_fim_assinatura']

for coluna in colunas_datas:
    df_membros[coluna] = pd\
    .to_datetime(df_membros[coluna], errors='coerce')\
    .dt.tz_localize(None)

# Ordenação das colunas
df_membros = df_membros[[
    'membro_id',
    'cliente_id',
    'dt_inicio_assinatura',
    'dt_fim_assinatura'
]]

# Tipagem
if df_membros['membro_id'].isna().any():
    raise ValueError('Membros com membro_id nulo')
else:
    df_membros['membro_id'] = df_membros['membro_id'].astype(int)

df_membros['cliente_id'] = df_membros['cliente_id'].astype(int)

# Exibição no terminal para conferência
# print('-' * 30)
# print('DADOS DE MEMBROS CARREGADOS:')
# print(df_membros.head())

# 4 ---  EXTRAÇÃO DE VENDAS (HTML) ---
url_vendas = os.getenv('URL_VENDAS')
tabelas = pd.read_html(url_vendas)
df_vendas = tabelas[0].copy()

# Renomear demais colunas
df_vendas = df_vendas.rename(columns={
    'Cliente': 'cliente_nome',
    'Produto': 'produto_id',
    'Data da venda': 'data_venda'
})

# Tratamento da data e renomeação da coluna
df_vendas['data_venda'] = df_vendas['data_venda']\
    .str.replace(' as ', ' ', regex=False)\
    .str.replace('h', ':', regex=False)

df_vendas['data_venda'] = pd.to_datetime(
    df_vendas['data_venda'],
    format='%d/%m/%Y %H:%M'
)

# Remoção de duplicatas
df_vendas = (
    df_vendas
    .drop_duplicates(subset=['cliente_nome', 'produto_id', 'data_venda'])
    .reset_index(drop=True)
)

# Limpeza da coluna cliente_nome nas tabelas vendas e cópia de clientes
df_vendas['cliente_nome'] = df_vendas['cliente_nome'].str.strip()

df_clientes_limpo = df_clientes.copy()
df_clientes_limpo['cliente_nome'] = df_clientes_limpo['cliente_nome'].str.strip()

# Criar e atribuição do cliente_id
df_clientes_merge = df_clientes_limpo[
    (df_clientes_limpo['cliente_nome'] != 'Daniel') |
    (df_clientes_limpo['cliente_id'] == 6)
]
df_vendas = pd.merge(
    df_vendas,
    df_clientes_merge[['cliente_id', 'cliente_nome']],
    on='cliente_nome',
    how='left'
)

# Criação de venda_id com auto incremento
df_vendas['venda_id'] = range(1, len(df_vendas) + 1)

# Tipagem
df_vendas['venda_id'] = df_vendas['venda_id'].astype(int)
df_vendas['produto_id'] = df_vendas['produto_id'].astype(int)
df_vendas['cliente_nome'] = df_vendas['cliente_nome'].astype(str)

if df_vendas['cliente_id'].isna().any():
    raise ValueError('Existem vendas sem cliente_id após o merge')
else:
    df_vendas['cliente_id'] = df_vendas['cliente_id'].astype(int)

# Reodernar colunas
colunas_ordenadas = [
    'venda_id',
    'cliente_id',
    'cliente_nome',
    'produto_id',
    'data_venda'
]
df_vendas = df_vendas[colunas_ordenadas]

# Visualização do resultado
# print('DADOS DE VENDAS CARREGADOS:')
# print(df_vendas.head())

# --- CONEXÃO COM DB ---
try:
    engine = get_engine()

    print('Enviando dados para o MySQL...')
    df_menu.to_sql('menu', con=engine, if_exists='replace', index=False)
    df_clientes.to_sql('clientes', con=engine, if_exists='replace', index=False)
    df_membros.to_sql('membros', con=engine, if_exists='replace', index=False)
    df_vendas.to_sql('vendas', con=engine, if_exists='replace', index=False)

    print('Sucesso! Tabelas criadas no MySQL.')
except Exception as e:
    print(f'Erro ao conectar ou enviar dados: {e}')
