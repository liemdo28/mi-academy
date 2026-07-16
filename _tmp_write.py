from pathlib import Path  
p = Path(r"d:\Project\mi-academy\infrastructure\docker\docker-compose.yml")  
p.parent.mkdir(parents=True, exist_ok=True)  
p.write_text('version: 3.9', encoding='utf-8')  
