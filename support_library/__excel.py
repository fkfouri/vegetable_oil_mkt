
from pathlib import Path
from time import sleep
import pandas as pd

import logging
log = logging.getLogger(__name__)


def save_excel(df, file_address, formatted = True):
    '''
    Create an excel file at the address provided
    '''
    log.debug(file_address)
    
    temp_address = Path(file_address)   
    
    while not temp_address.parent.exists():
        temp_address.parent.mkdir(parents=True, exist_ok=True)
    
    
    counter = 0
    max_error = 5
    
    while counter < max_error:
        sleep(1)
        try:
            if formatted:
                __save_excel_as_xlsxwriter(df, file_address)
            else:
                df.to_excel( file_address, index=False)
                
            return
        except Exception as e:
            log.error(f"Close the file: {e}")
            counter += 1
            
    if counter >= max_error:
        new_out = Path(f'{str(temp_address.parent)}').joinpath(f'{temp_address.stem}_temp{temp_address.suffix}')
        try:
            __save_excel_as_xlsxwriter(df, new_out)  if formatted else df.to_excel(new_out, index=False)
        except Exception as e:
            log.error(f"Close the file: {e}")
            counter += 1

    
    
    
 
def __save_excel_as_xlsxwriter(df, file_address):
    '''
    Create a formated excel file at the address provided
    '''
    writer = pd.ExcelWriter(file_address, engine='xlsxwriter')
        
    df.to_excel(writer, sheet_name='Sheet1', index=False)
    
    workbook  = writer.book
    worksheet = writer.sheets['Sheet1']

    header_format = workbook.add_format({'bold': True,
                                        'align': 'center',
                                        'valign': 'vcenter',
                                        'fg_color': '#D7E4BC',
                                        'border': 1})
    for col_num, value in enumerate(df.columns.values):
        worksheet.write(0, col_num, value, header_format)
    
    worksheet.freeze_panes(1, 1)
    
    (max_row, max_col) = df.shape
    worksheet.autofilter(0, 0, max_row, max_col - 1)
    
    for i, width in enumerate(get_col_widths(df)):
        worksheet.set_column(i, i, width)
    
    # Close the Pandas Excel writer and output the Excel file.
    writer.save()
    
    
    
    
def get_col_widths(dataframe):
    # First we find the maximum length of the index column   
    idx_max = max([len(str(s)) for s in dataframe.index.values] + [len(str(dataframe.index.name))])
    # Then, we concatenate this to the max of the lengths of column name and its values for each column, left to right
    return [max([len(str(s)) for s in dataframe[col].values] + [len(col)]) for col in dataframe.columns]
    return [idx_max] + [max([len(str(s)) for s in dataframe[col].values] + [len(col)]) for col in dataframe.columns]

