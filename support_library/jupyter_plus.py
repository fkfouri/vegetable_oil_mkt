from IPython.display import Markdown, display
import datetime

__version__ = datetime.datetime.now().timestamp()

def printmd(text):
    """ 
    Print texto em Markdown
    """
    display(Markdown(text))
    
def black(text):
    printmd(text)
    
def red(text):
    """ 
    Print texto em Markdown em Vermelho
    """
    return printmd(f"<span style='color:red'>{text}</span>")

def blue(text):
    """ 
    Print texto em Markdown em Azul
    """
    return printmd(f"<span style='color:blue'>{text}</span>")