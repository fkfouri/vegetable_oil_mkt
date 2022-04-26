# Tese FK





# Config 

## Virtual Env

- Para ambiente Windows:   
```
python -m venv .env-win-tese
.\.env-win-tese\Scripts\activate
python.exe -m pip install --upgrade pip
``` 

- Para ambiente Linux:
```
python -m venv .env-linux
source .env-linux/bin/activate
``` 

## Configurando Virtualenv para o Jupyter
[ref](https://janakiev.com/blog/jupyter-virtual-envs/)

- Instalação de Kernel: `pip install ipykernel`
- Configura Kernel para Jupyter: `python -m ipykernel install --name=env-win-tese`
- Exibe a lista de kernel Jupyter: `jupyter kernelspec list`
- Remoção de kernel jupyter: `jupyter kernelspec uninstall unwanted-kernel`


## Juputer Extension
- ref: https://towardsdatascience.com/jupyter-notebook-extensions-517fa69d2231
- `pip install jupyter_contrib_nbextensions`
- `jupyter contrib nbextension install`



https://www.google.com/search?q=supply+and+demand+python&rlz=1C1GCEB_pt-PTBR940BR940&oq=demmand+and+supply+python&aqs=chrome.1.69i57j0i22i30l2.11765j1j7&sourceid=chrome&ie=UTF-8
https://scholar.google.com.br/scholar?q=supply+and+demand+python&hl=pt-BR&as_sdt=0&as_vis=1&oi=scholart
https://docs.kinetica.com/7.1/guides/match_graph_dc_multi_supply_demand/
https://calc-again.readthedocs.io/en/latest/calc_notebooks/0.12_calc_consumer_surplus.html
https://dsfabric.org/modeling-single-good-market-in-python
https://openstax.org/books/principles-microeconomics/pages/3-2-shifts-in-demand-and-supply-for-goods-and-services
https://pt.khanacademy.org/economics-finance-domain/microeconomics/supply-demand-equilibrium/market-equilibrium-tutorial/v/changes-in-market-equilibrium?modal=1