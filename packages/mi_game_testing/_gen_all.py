import os,base64,codecs 
base = r'd:\Project\mi-academy\packages\mi_game_testing' 
def decode_and_write(b64, path): 
    full = os.path.join(base, path) 
    os.makedirs(os.path.dirname(full), exist_ok=True) 
