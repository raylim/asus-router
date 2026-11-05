from pathlib import Path
import urllib.request,urllib.parse,http.cookiejar,hashlib,re
class ATT:
 def __init__(self,base=None):
  self.creds={k.strip().upper():v.strip() for k,v in (l.split('=',1) for l in (Path.home()/'att_router.txt').read_text().splitlines() if '=' in l)}
  self.base=base or 'http://'+self.creds['IP'];self.cookies=http.cookiejar.CookieJar();self.opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.cookies))
  for _ in range(2):s=self.request('/cgi-bin/ippass.ha').decode(errors='replace')
  n=re.search(r'name="nonce"\s+value="([^"]*)"',s).group(1);p=self.creds['PASS']
  self.request('/cgi-bin/login.ha',{'nonce':n,'password':'*'*len(p),'hashpassword':hashlib.md5((p+n).encode()).hexdigest(),'Continue':'Continue'})
 def request(self,path,data=None):
  if data is not None:data=urllib.parse.urlencode(data).encode()
  host=urllib.parse.urlsplit(self.base).hostname
  headers={'Host':'['+host.split('%')[0]+']'} if ':' in host else {}
  req=urllib.request.Request(self.base+path,data=data,headers=headers)
  return self.opener.open(req,timeout=10).read()
