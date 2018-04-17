<IfModule mod_shib>
    <IfModule mod_proxy.c>
        <IfModule mod_ssl.c>
            SSLProxyEngine On
            SSLProxyCheckPeerCN Off
            SSLProxyCheckPeerName Off
        </IfModule>

        ProxyPreserveHost On
        ProxyRequests On

        <Location "%TARGET_LOCATION%">
            AuthType shibboleth
            ShibRequestSetting requireSession 1
            Require shib-session
            ProxyPass %TARGET_BACKEND%
            ProxyPassReverse %TARGET_BACKEND%
        </Location>
    </IfModule>
</IfModule>

