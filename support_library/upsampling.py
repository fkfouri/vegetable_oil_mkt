import pandas as pd

#######################################################################
# Usado pelo KNIME
#
# Tentativa de fazer o upsampling (Ano->Mes). 
# Usado Interpolacao linear. 
# - Ignora a sazonalidade
# - O Agrupamento dos meses em anos não dá o valor original (Acho isso errado)
#
#######################################################################

CHOICE = 'linear'
    
def up_sampling(df):
    
    col_year    = 'Market_Year'
    col_value   = 'Value'
    cols        = ['Commodity_Description', 'Reference', 'Attribute_Description']
    
    return __up_sampling(df, col_year, col_value, cols  )


def up_sampling_oecd(df):
    col_year    = 'Time'
    col_value   = 'Value'
    cols        = ['Commodity', 'Country', 'Variable']
    
    return __up_sampling(df, col_year, col_value, cols  )



def __up_sampling(df, col_year, col_value, cols ):
    all_cols    = cols + [col_year, col_value]
    
    df = df[all_cols].copy().sort_values(all_cols[:-1])
    
    # Obtido a variação do periodo YoY
    df['yoy'] = df.groupby(cols)[col_value].pct_change()
    df['yoy'].fillna(0, inplace=True)

    # Configurando o campo data para ser o ultimo dia no ano
    df['date'] = df[col_year].astype(str) + f'-1-1'
    df['date'] = pd.to_datetime(df['date'] , format='%Y-%m-%d')
    df['date'] = df['date'] + pd.DateOffset(years=1) + pd.Timedelta(days=-1) 
    df['year_value'] = df[col_value]
    df.set_index(['date'], inplace = True)
 
    #Realizando o resample por mes
    df_temp = df.groupby(cols)[[col_value, 'yoy', 'year_value']].resample('M').mean().reset_index()
    df_temp.set_index(['date'], inplace = True) 
    
    df_temp[col_value]      = round((df_temp[col_value]/12).interpolate(method=CHOICE, order=2), 2)
    df_temp['yoy']          = round((df_temp['yoy']).interpolate(method='bfill' ), 2)
    df_temp['year_value']   = round((df_temp['year_value']).interpolate(method='bfill' ), 2)

    # print(df_temp)
      
    # for commodity in df['Commodity_Description'].unique():
    #     _df = df_temp[df_temp['Commodity_Description'] == commodity]
    #     # print(_df)
    
    #     df_comp = compare_tecnicas(_df)
        
    #     # print(df_comp)
    #     # print(_df)

    #     _df= fix3_volume(_df, df_comp)
    #     print(_df.head(50))
        
    #     print(_df.groupby(pd.Grouper(freq='Y'))[['value_interpolate', 'value_fixed', 'year_value']].sum())
        
    #     pass
    
    df_temp.reset_index(inplace=True)
    
    
    return df_temp


def fix3_volume(df, comp):
    #Correcao do ponto central
    for idx, row in comp.iterrows():

        year = str(idx.year)
        qtd_months = df.loc[year].shape[0] 
        
        if qtd_months>1 and qtd_months<=12:
            correcao = row[f'err_{CHOICE}']
        else:
            correcao = 0
        
        df['value_fixed'] = df['year_value'] + correcao
        # df.at[year, 'value_fixed'] = correcao
        
    df['value_fixed'] = (df['value_fixed']/12).interpolate(method=CHOICE, order=2)

    return df



def compare_tecnicas(df):
    comp = df.copy().groupby(pd.Grouper(freq='Y'))[['year_value']].sum()
    methods = [ 'linear', 'spline', 'nearest', 'zero', 'slinear', 'quadratic', 'cubic',  'barycentric', 'polynomial', 'krogh', 'piecewise_polynomial', 'spline', 'pchip', 'akima', 'cubicspline']




    for me in methods:
        temp = df.copy()
        temp[me] = (temp['Value']/12).interpolate(method=me, order=2)
        
        comp2 = temp.groupby(pd.Grouper(freq='Y'))[[me, 'year_value']].sum()
        comp2[f'err_{me}'] = comp2[me] / comp['year_value']
        
        if CHOICE == me:
            df['value_interpolate'] = (df['Value']/12).interpolate(method=me, order=2)
            df['err_1']  = comp2[me] / comp['year_value']
            df['err_2']  = comp['year_value'] - comp2[me]
            # df['err'] = df['err'].interpolate(method='pad', limit_direction='forward', order=2)
        

        comp2[f'err_{me}'] = comp['year_value'] - comp2[me]
        
        comp = pd.merge(comp, comp2[f'err_{me}'], left_index=True, right_index=True)

    comp.reset_index()#.set_index('date')
    return comp




def fix_volume(df, comp):
    #Correcao do ponto central
    for idx, row in comp.iterrows():

        year = str(idx.year)
        
        start = 0 if df.loc[year].shape[0] == 1 else df.loc[year].shape[0]//2-1
        end = 1 if df.loc[year].shape[0] == 1 else df.loc[year].shape[0]//2
        
        value_interpolate = df.loc[year][start:end]['value_interpolate'][0]
        correcao =  value_interpolate + row['err_linear']
        index = df.loc[year][start:end].index[0]
        
        print(year, row['err_linear'], start, end, "===>", value_interpolate, correcao)
    #     sun2.at()9

        df.at[index, 'value_interpolate'] = correcao

    return df



def fix2_volume(df, comp):
    # TEntativa para correcao em alguns meses
    for idx, row in comp.iterrows():

        year = str(idx.year)
        
        months = [3, 9]
        
        for month in months:
            _idx = f'{year}-{month}'
            
            if _idx not in df.index:
                _idx = f'{year}-12'

    #         start = 0 if sun2.loc[year].shape[0] == 1 else sun2.loc[year].shape[0]//2-1
    #         end = 1 if sun2.loc[year].shape[0] == 1 else sun2.loc[year].shape[0]//2
    #         value_interpolate = sun2.loc[year][start:end]['value_interpolate'][0]

            value_interpolate = df.loc[_idx]['value_interpolate'][0]
            correcao =  value_interpolate + row['err_linear']/len(months)
            index = df.loc[_idx].index[0]
        
    #         print(_idx, row['err_linear'], start, end, "===>", value_interpolate, correcao)

            df.at[_idx, 'value_interpolate_meses'] = correcao

    return df







if __name__ == '__main__':
    # df = pd.read_excel(r'E:\Projetos\vegetable_oil_mkt\dataset\__knime_producao_anual.xlsx')
    # df['Market_Year'] = df['Market_Year'].astype(int)
    # x = up_sampling(df)
    
    df = pd.read_csv(r'E:\Projetos\vegetable_oil_mkt\dataset\HIGH_AGLINK_2021_16032022104718005.csv')
    print(df.shape)
    df['Time'] = df['Time'].astype(int)
    df = df[(df['Country'] == 'WORLD') & ( df['Commodity'] == 'Vegetable oils') ]
    print(df.shape)
    x = up_sampling_oecd(df) 
    
    print(x)
