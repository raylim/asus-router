from pathlib import Path
import urllib.request,urllib.parse,http.cookiejar,base64,json
class ASUS:
 def __init__(self,creds=None):
  self.base='http://192.168.1.1'
  self.creds=creds or {k.strip().lower():v.strip() for k,v in (l.split('=',1) for l in (Path.home()/'asus_router.txt').read_text().splitlines() if '=' in l)}
  self.cookies=http.cookiejar.CookieJar();self.opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.cookies))
  self.request('/Main_Login.asp')
  auth=base64.b64encode((self.creds['user']+':'+self.creds['password']).encode()).decode()
  self.request('/login.cgi',{'group_id':'','action_mode':'','action_script':'','action_wait':'5','login_authorization':auth,'login_captcha':'','next_page':'index.asp','current_page':'Main_Login.asp'})
  if not any(c.name=='asus_token' for c in self.cookies): raise RuntimeError('ASUS login did not return a session')
 def request(self,path,data=None):
  if data is not None:data=urllib.parse.urlencode(data).encode()
  referer='/Main_Login.asp' if path=='/login.cgi' else '/index.asp'
  req=urllib.request.Request(self.base+path,data=data,headers={'Referer':self.base+referer,'User-Agent':'Mozilla/5.0'})
  return self.opener.open(req,timeout=12).read()
 def nvram(self,fields):
  return json.loads(self.request('/appGet.cgi?'+urllib.parse.urlencode({'hook':';'.join('nvram_get('+k+')' for k in fields)})))
 def redact(self,s):
  for v in self.creds.values(): s=s.replace(v,'[credential withheld]')
  for c in self.cookies:s=s.replace(c.value,'[session withheld]')
  return s
