from sqlalchemy import create_engine

USUARIO = 'root'
SENHA = 'root'
HOST = 'localhost'
BANCO = 'padaria_db'

def get_engine():
    '''Retorna a conexão com o MySQL'''
    conexao_url = f'mysql+mysqlconnector://{USUARIO}:{SENHA}@{HOST}/{BANCO}'
    return create_engine(conexao_url)
