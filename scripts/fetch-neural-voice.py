import urllib.request,hashlib,json
from pathlib import Path
base='https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/'
root=Path('tools/voice');root.mkdir(exist_ok=True)
manifest=[]
for name in ['kokoro-v1.0.onnx','voices-v1.0.bin']:
 p=root/name
 if not p.exists():
  with urllib.request.urlopen(urllib.request.Request(base+name,headers={'User-Agent':'WildforgeBuild'}),timeout=120) as r:p.write_bytes(r.read())
 manifest.append({'file':name,'source':base+name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});print(name,p.stat().st_size)
(root/'sources.json').write_text(json.dumps(manifest,indent=2))
