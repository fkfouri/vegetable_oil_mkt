import json
import pandas as pd
import requests
import os

from datetime import date, timedelta, datetime
from urllib.parse import unquote, quote
from pathlib import Path

import logging
log = logging.getLogger("Source_MDIC")
requests.packages.urllib3.disable_warnings() 

get_env             = lambda env, default = None : os.environ.get(env) if env in os.environ else default
SSL_VERIFY          = bool(get_env('SSL_VERIFY', 0))

class Main():

    def __init__(self, **kwargs):
        log.debug(f'✔️ __init__') 
        self.kwargs = kwargs

    @property
    def datasource(self):
        return "MDIC" #__name__
    
    @property
    def primary_key(self):
        return self.pkey
        
    @property
    def hash(self):
        return True

    def read(self, symbol = 'general'):
        if self.__is_test(self.kwargs):
            raise Exception("This is a Redudance Test")

        START = datetime.strptime('1990-01-01', '%Y-%m-%d')
        END = datetime.strptime(f'{date.today().year}-12-01', '%Y-%m-%d')

        resp = self.__get_json(symbol, START, END)

        df = pd.DataFrame.from_dict(resp['data']['list'])

        df.rename(columns = {   'coAno': 'year', 
                                'coMes': 'month', 
                                'noPaisen': 'to_country',
                                'coSh4':'sh_code',
                                'vlFob':'fob',
                                'kgLiquido':'weight',
                                'qtEstat':'qty',
                                'noSh4en':'sh_description',
                                'noVia':'transport_mode',
                                'noUrf':'customs_unit',
                                'coNcm':'sh_code',
                                'noNcmen':'sh_description',                 
                                }, inplace = True)
        
        df['symbol'] = symbol

        if 'customs_unit' in df:
            code_regex = r'(\d{1,12})\s{1,5}\-{1,5}\s{1,5}'
            df['customs_name'] = df['customs_unit'].str.split(code_regex).str[2].str.strip()
            df['customs_unit'] = df['customs_unit'].str.split(code_regex).str[1].str.strip()

        if 'noMunMinsgUf' in df:
            split_ref = ' - '
            df['from_city'] = df['noMunMinsgUf'].str.split(split_ref).str[0].str.strip()
            df['from_city'] = df['from_city'].str.normalize('NFKD').str.encode('ascii', errors='ignore').str.decode('utf-8')

            df['from_state'] = df['noMunMinsgUf'].str.split(split_ref).str[1].str.strip()            
            df.drop(columns=['noMunMinsgUf','noUf'], inplace = True)

        #Ordenacao pela data
        #df = df.sort_values(by='date')[['date', 'close', 'open','high', 'low','volume','symbol']]
        return df 


    def __get_json(self, symbol, start, end):
        req = requests.get(url=self.__get_url(symbol) + self.__get_filter(symbol, start, end), 
                           verify=SSL_VERIFY, 
                           headers = self.__get_header, 
                           cookies= self.__get_cookies,
                           data = self.__get_payload).content.decode("utf-8")


        return json.loads(req)        
    

    @property
    def __get_header(self):
        return {
            "Host"          : "api.comexstat.mdic.gov.br",
            "Origin"        : "http://comexstat.mdic.gov.br",
            "Referer"       :"http://comexstat.mdic.gov.br/",
            "User-Agent"    : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Safari/537.36",   
        }

    @property
    def __get_cookies(self):
        return {}

    @property
    def __get_payload(self):
        return {}

    def __get_url(self, symbol):
        return f'http://api.comexstat.mdic.gov.br/{symbol}?filter='

    def __get_filter(self, symbol, start, end):
        
        sh_code = self.kwargs['sh_code'] if 'sh_code' in  self.kwargs else ['470321']
    

        base = {
            "typeForm"          :  1,
            "typeOrder"         :  2,
            "monthDetail"       :  "true",
            "metricFOB"         :  "true",
            "metricKG"          :  "true",
            "monthStart"        :  str(start.month).zfill(2),
            "yearStart"         :  str(start.year).zfill(4),
            "monthEnd"          :  str(end.month).zfill(2),
            "yearEnd"           :  str(end.year).zfill(4),
            "langDefault"       :  "en",
            "monthStartName"    :  start.strftime('%B'),
            "monthEndName"      :  end.strftime('%B'),        
        }

        if symbol == 'general':
            self.pkey = ['year','month','sh_code','to_country','customs_unit','customs_name']
            
            
            query = {
                "filterList"        :  [{
                            "id"            : "noSh6en",
                            "text"          : "Subheading (SH6)",
                            "route"         : "/en/harmonized-system/subposition",
                            "type"          : "2",
                            "group"         : "sh",
                            "groupText"     : "Harmonized System (HS)",
                            "hint"          : "fieldsForm.general.noSh6.description",
                            "placeholder"   : "Subheading (SH6)"
                }],
                "filterArray"       :  [{
                                            "idInput"       :   "noSh6en",
                                            "item"          :   [ f'{x}00'[:6] for x in sh_code] ,
                                        }],
                "rangeFilter"       :  [],
                "detailDatabase"    :  [{   
                            "id"            :   'noSh6en',
                            "text"          :   "Subheading (SH6)",
                            "parent"        :   "SH6 Code",
                            "parentId"      :   "coSh6",
                        }, {
                                            "id"            :   "noPaisen",
                                            "text"          :   "Country",
                                        },
                                        {
                                            "id": "noVia",
                                            "text": "Via"
                                        }, {
                                            "id": "noUrf",
                                            "text": "URF"
                                        }
                ],           
                "metricStatistic"   :  "true",
                "formQueue"         :  "general",
            }
            
        elif symbol == 'cities':
            self.pkey = ['year','month','sh_code','to_country','from_city','from_state']
            
            sh4_filter = 'Heading (SH4)'
            query={
                    "filterList"        :  [{                  
                                                "id"            : "noSh4en",
                                                "text"          : sh4_filter,
                                                "route"         : "/en/harmonized-system/position",
                                                "type"          : "2",
                                                "group"         : "sh",
                                                "groupText"     : "Harmonized System (HS)",
                                                "hint"          : "fieldsForm.city.noSh4.description",
                                                "placeholder"   : sh4_filter          
                                            }],
                    "filterArray"       :  [{
                                                "idInput"       :   "noSh4en",
                                                "item"          :   [x[:4] for x in sh_code],
                                            }],
                    "rangeFilter"       :  [],
                    "detailDatabase"    :  [
                                            {                                          
                                                "id"            :   "noSh4en",          #"noNcmpt"
                                                "text"          :   sh4_filter,         #"NCM - Nomenclatura Comum do Mercosul"
                                                "parent"        :   "SH4 Code",         #"Código NCM"
                                                "parentId"      :   "coSh4",            #"coNcm"
                                            }, 
                                            {               
                                                "id"            :   "noMunMin",
                                                "text"          :   "City",
                                                "concat"        :   "noMunMinsgUf", 
                                            }, 
                                            { "id": "noUf",      "text": "State of company" }, 
                                            { "id": "noPaisen",  "text": "Country" },
                                        ],
                    "formQueue"         :  "city",
                }

        filter = {**base, **query}
        
        
        return json.dumps(filter, indent=4, sort_keys=False)
        
        #output= json.dumps(filter)
        #return quote(output, safe='')

    def __is_test(self, k):
        this_test = self.datasource
        if 'unit_test' in k and k['unit_test'] == True and this_test in k and k[this_test] == False:
            return True
        return False



if __name__ == "__main__": # pragma: no cover
    print('The library "{0}" cannot be run directly'.format(Path(__file__).name))

    c = Main()
    x = c.read('general')
    print(x)

 