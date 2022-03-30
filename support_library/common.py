import base64
import numpy as np
import pandas as pd
import datetime

import logging
log = logging.getLogger(__name__)

__version__ = datetime.datetime.now().timestamp()

def desativa_notacao():
    """Desativa a notacao cientifica de exibicao AGG do pandas """
    pd.set_option('display.float_format', lambda x: '%.3f' % x)
    return pd

def get_raw_sheets(xls):
    """
    Obtem um dicionario com todas as planilhas em estado raw (bruto) de um Excel fornecido
    """
    sheet_to_df_map = {}
    for sheet_name in xls.sheet_names:
        sheet_to_df_map[sheet_name] = xls.parse(sheet_name)  
    return sheet_to_df_map  
    
    

def normalize_to_number(df: pd.DataFrame, to_ignore: list = []):
    """
    Converte os campos que contém dados númericos no tipo Number (Int64 ou Float64)
    Returns:
        Dataframe
    Args:
        df (pd.DataFrame): Dataframe to normalize

    Returns:
        Pandas Dataframe
    """
    # log.debug(f"Antes Normalização: {df.dtypes}")
    # Substitui valor não informados '-' por Nan
    df = df.replace('-', pd.NA)
    
    #Obtem as colunas unicas (nomes)
    unique_columns = df.loc[:,~df.columns.duplicated()].columns
    
    #colunas com tipo nao definido
    cols_to_transform = df.select_dtypes(include=['object']).columns
    
    #remove ignore
    cols_to_transform = [ele for ele in cols_to_transform if ele not in to_ignore]
    
    #conversao das colunas para tipo float
    df[cols_to_transform] = df[cols_to_transform].apply(pd.to_numeric, errors='ignore', downcast='float')
    
    # log.debug(f"Depois Normalização: {df.dtypes}")
    return df



def normalize_date(x):
    
    from datetime import datetime
    from dateutil.relativedelta import relativedelta
    
    if not pd.isnull(x):
        if isinstance(x, datetime):
            return x
        elif isinstance(x, (int, float)):
            return datetime.fromordinal(datetime(1900, 1, 1).toordinal() + int(x) - 2 )
        else:
            #https://strftime.org/
            return datetime.strptime(f'1 {x}', '%d %b %Y') + relativedelta(months=1) + relativedelta(days=-1)
    else:
        return x
    
    
    
def remove_accents(input_str):
    """Remocao de caracteres """
    import unicodedata
    nfkd_form = unicodedata.normalize('NFKD', str(input_str))
    only_ascii = nfkd_form.encode('ASCII', 'ignore')
    
    de = "-/$()[]{}"
    para = "__S      "
    terms = "\\.!?><,;:~\"'^*¨|`´ªº§+=&%#@"
    mytable = "".maketrans(de, para, terms)
    
    return '_'.join(only_ascii.strip().decode('utf-8').replace("\n","") \
                    .strip().translate(mytable).replace('_',' ').split())
        
            
            
def normalize_columns_names(df):
    """ 
    Limpa os nomes das colunas
    """
    out_df = df.copy()
    for col in out_df.columns:
        out_df.rename(columns = {col: remove_accents(col).upper()}, inplace = True)
    return out_df


def normalize_rows_values(df, col):
    """ 
    Normaliza os valores de uma coluna
    """
    out_df = df.copy()
    out_df[col] = out_df[col].apply(lambda x : remove_accents(x))

    return out_df

  
def convert_quilo_kton(df: pd.DataFrame):
    """
    Converte dados de quilo para Kilo Toneladas

    Args:
        df (pd.DataFrame): _description_

    Returns:
        df (pd.DataFrame): _description_
    """
    out_df = df.copy()
    lista1 = out_df.columns
    lista2 = ["QUILOGRAMA", 'PESO_KG', 'weight']
    
    for col in [item_lista1 for item_lista1 in lista1 for item_lista2 in lista2 if item_lista2.upper().strip() in item_lista1.upper().strip()]:

        out_df[col] = out_df[col]/1000/1000
        for item in lista2:
            out_df.rename(columns = {col: col.replace(item,"KTON")}, inplace = True)
    
    return out_df



def lowercase_for_dict_keys(input_dict):
    '''
    baseado em https://gist.github.com/avalanchy/edd5e93a6b0e72f69a929ef0588c48be
    '''
    out_dict = {}
    for k, v in input_dict.items():
        if isinstance(v, dict):
            v = lowercase_for_dict_keys(v)
        out_dict[k.lower()] = v
    return out_dict



def merge_lines_as_title(df, start_line, finish_line):
    out_df = df.copy()
    
    #agrupa as duas primeiras linhas como titulo
    df_title = df.iloc[start_line:finish_line, :].copy() 
    
    #preenche os campos nan do titulo somente das linhas titulos
    df_title = df_title.T.fillna(method='ffill').T.fillna(method='ffill')
    
    #agrupa/merge das linhas
    df_title['ref'] = 'title'
    df_title = df_title.groupby(['ref']).agg(lambda x: __merge_title(x) ) 

    #Troca os titulos das colunas
    out_df.columns = df_title.iloc[0]
    
    # Remove as suas primeiras linhas linha
    out_df = out_df.iloc[finish_line: , :].reset_index(drop = True)
    
    return normalize_columns_names(out_df)
    

def __merge_title(x): # pragma: no cover
    #Cria uma lista de itens unicos sem perder a sequencia de entrada. O comando set perde a ordem
    #baseado neste link https://www.geeksforgeeks.org/python-ways-to-remove-duplicates-from-list/
    step10 =  [i for n, i in enumerate(x) if i not in list(x[:n]) ]
    #Remove texto indesejado. Ex (kt)
    # step20 = [y.split('(')[0].strip() for y in step10]
    #Join
    step30 = '_'.join(step10).replace(" ", "_")
    return step30



def remove_columns_with_dulicate_values(df: pd.DataFrame):
    """Remove do dataframe colunas com o mesmo valor

    Args:
        df (pd.DataFrame): [description]

    Returns:
        [type]: [description]
    """
    from itertools import combinations
    
    cols_to_remove=[]
    cols_to_preserve = []
    
    #Identifica columnas com o mesmo valor em toda a serie
    for i,j in combinations(df,2):
        if df[i].equals(df[j]): 
            if j not in cols_to_remove: # pragma: no cover
                cols_to_remove.append(j)

            if i not in cols_to_preserve and i not in cols_to_remove: # pragma: no cover
                cols_to_preserve.append(i)
       
    log.debug(f'cols_to_preserve: {cols_to_preserve} | cols_to_remove: {cols_to_remove}')
    
    # Remove as colunas
    df = df.copy().drop(columns = cols_to_remove)
    
    return df



def decode_msg(msg, to_tupper = True):
    """
    Convert received message from pub/sub to string
    """
    log.debug(f'✔️ decode_msg')
    
    msg_to_decode = msg['data'] if isinstance(msg, dict) and 'data' in msg else msg
    msg_as_byte =  msg_to_decode.encode('utf-8') if not isinstance(msg_to_decode, (bytes, bytearray)) else msg_to_decode
    
    try:
        msg_as_string = base64.b64decode(msg_as_byte).decode('utf-8').strip()
    except Exception:
        msg_as_string = msg_as_byte.decode('utf-8').strip()
        
    return msg_as_string.upper() if to_tupper else msg_as_string
    



def encode_msg(message):
    log.debug(f'✔️ encode_msg')
    message_bytes = message.encode('utf-8')
    
    return {
        'data': base64.b64encode(message_bytes)
    }    




def remove_outliers(df, ref):
    Q1 = df[ref].quantile(.25)
    Q3 = df[ref].quantile(.75)
    IIQ = Q3 - Q1
    limite_inferior_latitude = Q1 - 1.5 * IIQ
    limite_superior_latitude = Q3 + 1.5 * IIQ
    return df[(df[ref] >= limite_inferior_latitude) & (df[ref]<= limite_superior_latitude)]