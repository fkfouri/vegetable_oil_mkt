import pandas as pd
import numpy as np
import json
import importlib, sys, os, requests
import yfinance as yf

from datetime import date, datetime

from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parents[1]))

# import support_library.common as common

DATE_FORMAT = '%Y-%m-%d'
MIN_DATE    = "2010-01-01"
TODAY       = date.today()
TODAY_STR   = date.today().strftime(DATE_FORMAT)

def convert(symbol):
    """
    Retorna o nome, fator correcao para dolar
    """
    symbol = symbol.lower()
    if symbol=='zl':
        return 'sb_oil', 1/100 * 2204.623 # centavos em dolar, lbs em Metric Ton
    elif symbol=='zs':
        return 'sb_grain', 1/100 * 36.7437 # centavos em dolar, buchel em Metric Ton
    elif symbol=='zm':
        return 'sb_meal', 1 * 1.102311  # Tonelada Curta em Metric Ton (Ja esta em dolar)
    return None, None

def get_futures(symbol):
    df = yf.Ticker(f"{symbol}=F").history(period="max")
    name, fator = convert(symbol)
    
    df[f'close']  = round(df['Close'] * fator, 2)
    df[f'volume'] = df['Volume']

    #Filtro
    df = df[df.index > pd.to_datetime(MIN_DATE, format=DATE_FORMAT)] 
    
    #remove outliers
    df = remove_outliers(df, 'close')
    
    return df.iloc[:,-2:].rename(columns={"close": f'{name}_future_price' , "volume": f'{name}_future_volume'})



def get_spot(symbol):
    name, fator = convert(symbol)
    link = f'https://api.nasdaq.com/api/quote/{symbol}/historical?assetclass=commodities&fromdate=2001-01-01&limit=99999&todate={TODAY_STR}'

    headers={'authority':'api.nasdaq.com',
            'user-agent':"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36"}

    req = requests.get(link, headers=headers)

    df = pd.DataFrame(req.json()['data']['tradesTable']['rows'])
    # df = common.normalize_to_number(df)
    df['date']      = pd.to_datetime(df['date'], infer_datetime_format=True) 
    df.set_index('date', inplace=True)
    
    df['close']     = pd.to_numeric(df['close'], errors='coerce')
    df['volume']    = pd.to_numeric(df['volume'].str.replace(',',''), errors='coerce')
       
    df = df[df['close'] > 0]
    
    df['close']     = round(df['close'] * fator, 2)
    df = df.fillna(0)
    df['volume']    = df['volume'].astype(int)

    #Filtro
    df = df[df.index > pd.to_datetime(MIN_DATE, format=DATE_FORMAT)] 
    
    #remove outliers
    df = remove_outliers(df, 'close')
    
    return df.iloc[:,:2].rename(columns={"close": f'{name}_spot_price' , "volume": f'{name}_spot_volume'})


def remove_outliers(df, ref):
    Q1 = df[ref].quantile(.25)
    Q3 = df[ref].quantile(.75)
    IIQ = Q3 - Q1
    limite_inferior_latitude = Q1 - 1.5 * IIQ
    limite_superior_latitude = Q3 + 1.5 * IIQ
    return df[(df[ref] >= limite_inferior_latitude) & (df[ref]<= limite_superior_latitude)]


def get_all():
    df_soja = get_futures(symbol='zs')
    df_soja = pd.merge(df_soja, get_spot('zs'), how="left", left_index=True, right_index=True)
    df_soja = pd.merge(df_soja, get_futures(symbol='zl'), how="left", left_index=True, right_index=True)
    df_soja = pd.merge(df_soja, get_spot(symbol='zl'), how="left", left_index=True, right_index=True)

    df_soja = pd.merge(df_soja, get_futures(symbol='zm'), how="left", left_index=True, right_index=True)
    df_soja = pd.merge(df_soja, get_spot(symbol='zm'), how="left", left_index=True, right_index=True)
    df_soja['date'] = df_soja.index
    df_soja.dropna(inplace= True)
    return df_soja

if __name__ == "__main__":
    # x = get_futures(symbol='zs')
    # x = get_spot(symbol='zm')
    x = get_all()


    print(x)
    print(x.shape)
    print(x.describe())