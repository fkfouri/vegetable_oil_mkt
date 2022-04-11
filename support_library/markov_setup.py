from random import randint
from xmlrpc.client import Boolean
from tqdm import tqdm
import pandas as pd
import numpy as np

import logging
log = logging.getLogger(__name__)


def quantiles_v2(df: pd.DataFrame, labels: list):
    df    = df.copy()
    ref   = ''.join(labels).lower()
    size  = len(labels)

    columns_production  = []
    columns_exports     = []
    columns_prices      = []
    for col in df.columns:
        column_name         = f'{col}_qcut'
        
        if 'production_variation' in col:

            df[column_name]     = pd.qcut(df[col], q=size, labels = labels)
            columns_production.append(column_name)
            
        elif 'exports_variation' in col:
            df[column_name]     = pd.qcut(df[col], q=size, labels = labels)
            columns_exports.append(column_name)            
            
        elif 'price_variation' in col:
            df[column_name]     = pd.qcut(df[col], q=size, labels = labels)
            columns_prices.append(column_name)  
            
    def get_equation(columns):
        return ' + '.join( [f'df["{col}"].astype(str)' for col in columns] )
        
    df['event_pattern_production']  = eval(get_equation(columns_production)) 
    df['event_pattern_exports']     = eval(get_equation(columns_exports)) 
    df['event_pattern_prices']      = eval(get_equation(columns_prices)) 
    
    columns_fixed   = list(df.columns[:4])
    columns_sort    = sorted(list(df.columns[4:-3]))
    columns_event   = sorted(list(df.columns[-3:]))
    
    columns_production.append('event_pattern')

    return df[columns_fixed + columns_sort + columns_event].sort_values(by = ['Close_Date'], ascending=[False])
    return df
    return df[['Sequence_ID','Close_Date'] + columns_production]
    

    

# Creating random sets of sequential rows (i.e. weeks) and calculating PIX variations WoW

def get_random_sets(input_dataframe: pd.DataFrame, 
                    size = 100000,
                    **kwargs):
    
    # take random sets of sequential rows 
    new_set = []
    

    for row_set in (pbar :=  tqdm(iterable = range(0, size), bar_format='{desc:<15}{percentage:3.0f}%|{bar:50}{r_bar}' ) ):
        
        pbar.set_description("get_random_sets")
        row_quant     = randint(10, 30)
        row_start     = randint(0, len(input_dataframe) - row_quant)
        row_finish    = row_start + row_quant
        
        market_subset = input_dataframe.iloc[row_start:row_finish]
        
        Close_Date    = max(market_subset['date'])

        if row_set%(size//5)==0:
            pass
            print(f'row_set: {row_set:<6} | row_quant: {row_quant:2} | rows: {row_start:>6}-{row_finish-1:<6} | market_subset: {str(market_subset.shape):^10} | Close_Date: {Close_Date:%m/%d/%Y}')
        
        ref = {}
        ref['Sequence_ID']  = [row_set]*len(market_subset)          # poderia ser 'row_quant' ao inves de 'len(market_subset)'
        ref['Close_Date']   = [Close_Date]*len(market_subset)
        ref['ref_date']   = market_subset['date']
        
        columns_ref = {}
        
        if 'columns' in kwargs and isinstance(kwargs['columns'], list):
            for _col in kwargs['columns']:
                if _col in input_dataframe.columns:
                    columns_ref[_col] = market_subset[_col]
                    columns_ref[f'{_col}_variation'] = market_subset[_col].pct_change()
                    
                    if 'outcomes' in kwargs and isinstance(kwargs['outcomes'], list) and _col in kwargs['outcomes']:
                        # columns_ref[f'{_col}_outcome'] = market_subset[_col].shift(-1) - market_subset[_col]
                        columns_ref[f'{_col}_outcome'] = market_subset[_col].diff(-1) * -1
            
        
        if 'bypass' in kwargs and isinstance(kwargs['bypass'], list):
            for _col in kwargs['bypass']:
                columns_ref[_col] = market_subset[_col]
               
        # columns_ref = dict( sorted(columns_ref.items(), key=lambda x: x[0].lower()) )
        
        #merge dictionaries
        ref = {**ref, **columns_ref}
        
        new_set.append(pd.DataFrame(ref))
        
    return new_set


def convet_collection_to_dataframe(collection):
    df_out = pd.concat(collection)
    
    log.debug(f'Before dropping NaNs: {df_out.shape}')
    df_out.replace([np.inf, -np.inf], np.nan, inplace=True)
    df_out = df_out.dropna(how='any') 
    log.debug(f'After dropping NaNs: {df_out.shape}')
    return df_out



import pickle
from pathlib import Path

def get_pickle_filename(file_name):
    file_name = Path(file_name)
    
    if file_name.suffix == '.pkl':
        file_name = Path(f'{file_name}.zip')
    elif file_name.suffix == '':
        file_name = Path(f'{file_name}.pkl.zip')
    
    return file_name
    


def export_dataframe(input_dataframe: pd.DataFrame,
                     file_name):
    input_dataframe.to_pickle(get_pickle_filename(file_name), compression='zip')
    # input_dataframe.to_parquet(str(file_name), compression='gzip')
    
def import_dataframe(file_name):
    return pd.read_pickle(get_pickle_filename(file_name), compression='zip')



get_divison = lambda size: [item / size for item in list(range(size + 1))]
get_labels = lambda size: [f'{chr( (item % 26) + 65 )}{ "" if item // 26 <= 0 else item // 26 }' for item in list(range(size))]
get_full = lambda size: [ (chr(i + 65), f'{j / size} < x <= { (j+1) / size}' ) for i , j in enumerate(range(size))]
get_bins = lambda _input_array, size:  np.round(np.linspace(_input_array.min(), _input_array.max(), size + 1), 6).tolist()


def read_kwarg_list(kwargs, name, _else_conditions = None):
    if name in kwargs and isinstance(kwargs[name], list):
        return kwargs[name]
    return _else_conditions

def read_kwarg_bool(kwargs, name):
    if name in kwargs and isinstance(kwargs[name], Boolean):
        return kwargs[name]
    return False
        
    
def quantiles(input_dataframe: pd.DataFrame, number_of_bins, **kwargs):
    
    df_out = input_dataframe.copy()
    out_columns = list(df_out.columns)
    log.debug


    labels          = read_kwarg_list(kwargs,'labels', get_labels(number_of_bins))
    columns         = read_kwarg_list(kwargs,'columns')
    
    
    if columns:
        columns_labels = []
        for _col in columns:
            if _col in out_columns:
                column_name = f'{_col}_label'
                columns_labels.append(column_name)
                
                ii = max([i for i, item in enumerate(out_columns) if _col in item])
                
                if column_name not in out_columns:
                    out_columns.insert(ii + 1, column_name)

                df_out[column_name], cut_intervals = pd.qcut(df_out[_col], q=number_of_bins, labels=labels, retbins=True)
                log.debug(f'cut_intervals of {_col}: {cut_intervals}')
         
         
        if read_kwarg_bool(kwargs, 'event_pattern'):
            equation = ' + '.join( [f'df_out["{e}"].astype(str)' for e in columns_labels] )
            df_out['event_pattern']  = eval(equation) 
            out_columns.append('event_pattern')
        
            log.debug(f"Unique event_patterns: {df_out['event_pattern'].unique()}")
            
            
    return df_out[out_columns]
    
    
    
def compress(input_dataframe: pd.DataFrame, **kwargs):
    columns         = read_kwarg_list(kwargs,'columns')
    outcomes        = read_kwarg_list(kwargs,'outcomes')
    
    if columns and 'event_pattern' in input_dataframe.columns:
        df_step1 = input_dataframe.groupby(columns)['event_pattern'].apply(lambda x: ','.join(x)).reset_index()
        
    if columns and outcomes:
        df_step2 = input_dataframe.groupby(columns)[outcomes].mean()
        
    compressed_set = pd.merge(df_step1, df_step2, on= columns, how='inner')
    
    return compressed_set



def get_unique_patterns(input_array: np.ndarray, **kwargs):
    """ 
    Aqui o 'get_labels' nao deve fazer parte... pois os unique patterns pode estar agrupado. Ex. AAA, ABC, etc
    """
    flat_list = [ item.split(',') for item in input_array ]
    unique_patterns = ','.join(str(r) for v in flat_list for r in v)
    unique_patterns = sorted(list( set( unique_patterns.split(',') ) ))
    return unique_patterns


def build_transition_grid(input_dataframe: pd.DataFrame, unique_patterns):
    log.debug(f'unique_patterns ==> {unique_patterns}')
    
    # build the markov transition grid

    patterns = []
    counts = []
    counts_fk = {}
    
    # de
    for from_event in unique_patterns:
        # para
        
        for to_event in unique_patterns:
            
            pattern = from_event + ',' + to_event # MMM,MlM
            

            ids_matches = input_dataframe[input_dataframe['event_pattern'].str.contains(pattern)]
            
            
            found = 0
            if len(ids_matches) > 0:
                Event_Pattern = '---'.join(ids_matches['event_pattern'].values)
                found = Event_Pattern.count(pattern)
                
            log.debug(f'pattern => {pattern} | ids_matches: {len(ids_matches)} | found: {found} ')
            patterns.append(pattern)
            counts.append(found)
            
            counts_fk[pattern] = f'{len(ids_matches)}|{found}'
    
    # log.debug(f'patterns: {patterns}')
    # log.debug(f'counts: {counts}')
    # log.debug(counts_fk)

    # create to/from grid
    grid_markov = pd.DataFrame({'pairs':patterns, 'counts': counts})
    
    # return grid_markov

    ## Warning
    # grid_markov['x'], grid_markov['y'] = grid_markov['pairs'].str.split(',').str
    
    grid_markov[['x', 'y']] = grid_markov['pairs'].str.split(',', n=1, expand=True)
    
    # return grid_markov

    grid_markov = grid_markov.pivot(index='x', columns='y', values='counts')
    
    # return grid_markov

    # log.debug(f'Antes Columns :{grid_markov.columns}')
    grid_markov.columns= [col for col in grid_markov.columns]
    # log.debug(f'Depois Columns :{grid_markov.columns}')
    
    # return grid_markov
   

    # replace all NaN with zeros
    grid_markov.fillna(0, inplace=True)
    
    grid_markov['soma'] = grid_markov.sum(axis=1)
    
    # return grid_markov

    # grid_markov.rowSums(transition_dataframe) 
    # grid_markov = grid_markov / grid_markov['soma']
    
    for col in grid_markov.columns:
        grid_markov[col] = grid_markov[col]/grid_markov['soma']
        
        
    del grid_markov['soma']

    return grid_markov
    # return (grid_markov)

# build_transition_grid(df5_pos, unique_patterns)



def predict_something(df_validation: pd.DataFrame, 
                      df_positive: pd.DataFrame, 
                      df_negative: pd.DataFrame):
    actual = []
    predicted = []
    for seq_id in df_validation['Sequence_ID'].values:
        patterns = df_validation[df_validation['Sequence_ID'] == seq_id]['Event_Pattern'].values[0].split(',')
        pos = []
        neg = []
        log_odds = []

        for id in range(0, len(patterns)-1):
            # get log odds
            # logOdds = log(tp(i,j) / tn(i,j)
            if (patterns[id] in list(df_positive) and patterns[id+1] in list(df_positive) and patterns[id] in list(df_negative) and patterns[id+1] in list(df_negative)):

                numerator = df_positive[patterns[id]][patterns[id+1]]
                denominator = df_negative[patterns[id]][patterns[id+1]]
                if (numerator == 0 and denominator == 0):
                    log_value =0
                elif (denominator == 0):
                    log_value = np.log(numerator / 0.00001)
                elif (numerator == 0):
                    log_value = np.log(0.00001 / denominator)
                else:
                    log_value = np.log(numerator/denominator)
            else:
                log_value = 0

            log_odds.append(log_value)

            pos.append(numerator)
            neg.append(denominator)

        print('outcome:', df_validation[df_validation['Sequence_ID']==seq_id]['Outcome_Next_Day_Direction'].values[0])
        print(sum(pos)/sum(neg))
        print(sum(log_odds))

        actual.append(df_validation[df_validation['Sequence_ID']==seq_id]['Outcome_Next_Day_Direction'].values[0])
        predicted.append(sum(log_odds))
        
        
def safe_log(numerator, denominator):

    if numerator <= 0 and denominator <= 0:
        log_value = 0
    elif denominator <= 0:
        log_value = np.log(numerator / 0.00001)
    elif numerator <= 0:
        log_value = np.log(0.00001 / denominator)
    else:
        log_value = np.log(numerator / denominator)
        
    return log_value


def build_transition_grid_v2(df: pd.DataFrame, unique_patterns):
    '''
    build the markov transition grid
    '''
    patterns  = []
    counts    = []
    counts_fk = {}
    
    #unique_patterns = unique_patterns[:3]
    event_patterns  = [x for x in df2.columns if 'event_pattern' in x  ]
    
    # de
    for from_event in unique_patterns:
        # para
        for to_event in unique_patterns:
            
            pattern_to_search = from_event + ',' + to_event # MMM,MlM
            log.debug(pattern_to_search)
            
            # event_pattern_prices
            # event_pattern_exports
            # event_pattern_production
            
            for col in event_patterns:                
                ids_matches = df[df[col].str.contains(pattern_to_search)]

                found = 0
                if len(ids_matches) > 0:
                    Event_Pattern = '---'.join(ids_matches[col].values)
                    found = Event_Pattern.count(pattern_to_search)

                log.debug(f'pattern_to_search => {pattern_to_search} | ids_matches: {len(ids_matches)} | found: {found} ')
                patterns.append(pattern_to_search)
                counts.append(found)

                counts_fk[pattern_to_search] = f'{len(ids_matches)}|{found}'
            
    
    log.debug(f'patterns: {patterns}')
    log.debug(f'counts: {counts}')
    log.debug(f'counts_fk: {counts_fk}')

    # create to/from grid
    grid_markov = pd.DataFrame({'pairs':patterns, 'counts': counts})
    log.debug(f'CRIACAO GRID: {grid_markov}')
    
    # group by, para remover as duplicacoes de multiplos patterns
    grid_markov = grid_markov.groupby(['pairs'])['counts'].sum().to_frame().reset_index()
    log.debug(f'GRID GROUPED: {grid_markov}')

    # quebra em x,y a coluna combinada
    grid_markov[['x', 'y']] = grid_markov['pairs'].str.split(',', n=1, expand=True)
    log.debug(f'GRID X,Y: {grid_markov}')

    # pivoteamento em x e y
    grid_markov = grid_markov.pivot(index='x', columns='y', values='counts')
    log.debug(f'GRID PIVOT: {grid_markov}')
    
    # Renomeia as colunas. Remove a referencia 'y'
    grid_markov.columns= [col for col in grid_markov.columns]
    log.debug(f'GRID RENAME COLUMNS :{grid_markov}')
    
    # replace all NaN with zeros
    grid_markov.fillna(0, inplace=True)
    log.debug(f'GRID FILLNA :{grid_markov}')
    
    # cria uma coluna temporaria para a soma da linha
    grid_markov['soma'] = grid_markov.sum(axis=1)
    log.debug(f'GRID SOMA :{grid_markov}')
    
    # return grid_markov

    # grid_markov.rowSums(transition_dataframe) 
    # grid_markov = grid_markov / grid_markov['soma']
    
    # calcula o percentual de cada valor sobre a soma    
    for col in grid_markov.columns:
        grid_markov[col] = grid_markov[col]/grid_markov['soma']
    log.debug(f'GRID PERCENT :{grid_markov}')
        
        
    # replace all NaN with zeros. Para o caso da divisao por zero (soma)
    grid_markov.fillna(1/(x.shape[1] - 2), inplace=True)
    log.debug(f'GRID FILLNA :{grid_markov}')
    
    
    #Remove a coluna Soma    
    del grid_markov['soma']

    return grid_markov