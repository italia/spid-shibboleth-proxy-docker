<html>
    <head>
        <title>Access</title>
    </head>
    <body>
        <ul>
            <li>
                <a href="https://%SERVER_NAME%/iam/Login?target=https://%SERVER_NAME%/whoami&entityID=https://idp.spid.gov.it">
                Test on <tt>/whoami</tt> (lucia/password123)
                </a>
            </li>
            <li>
                <a href="https://%SERVER_NAME%/iam/Login?target=https://%SERVER_NAME%%TARGET_LOCATION%&entityID=https://idp.spid.gov.it">
                Test on <tt>%TARGET_LOCATION%</tt> (lucia/password123)
                </a>
            </li>
        </ul>
    </body> 
</html>

