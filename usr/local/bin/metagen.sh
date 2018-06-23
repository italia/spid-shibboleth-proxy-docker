#!/usr/bin/env bash

DECLS=1

SAML1=0
SAML2=0
ARTIFACT=0
DS=0
LOGOUT=0
NAMEIDMGMT=0

SAML10PROT="urn:oasis:names:tc:SAML:1.0:protocol"
SAML11PROT="urn:oasis:names:tc:SAML:1.1:protocol"
SAML20PROT="urn:oasis:names:tc:SAML:2.0:protocol"

SAML20SOAP="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
SAML20REDIRECT="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
SAML20POST="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
SAML20POSTSS="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign"
SAML20ART="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
SAML20PAOS="urn:oasis:names:tc:SAML:2.0:bindings:PAOS"

SAML1POST="urn:oasis:names:tc:SAML:1.0:profiles:browser-post"
SAML1ART="urn:oasis:names:tc:SAML:1.0:profiles:artifact-01"

while getopts a:c:e:f:h:l:n:o:s:t:u:12ADLNO c
     do
         case $c in
           c)   CERTS[${#CERTS[*]}]=$OPTARG;;
           e)   ENTITYID=$OPTARG;;
           f)   FORMATS[${#FORMATS[*]}]=$OPTARG;;
           h)   HOSTS[${#HOSTS[*]}]=$OPTARG;;
           l)   HOSTLIST=$OPTARG;;
           n)   NAKEDHOSTS[${#NAKEDHOSTS[*]}]=$OPTARG;;
           o)   ORGNAME=$OPTARG;;
           a)   ADMIN[${#ADMIN[*]}]=$OPTARG;;
           s)   SUP[${#SUP[*]}]=$OPTARG;;
           t)   TECH[${#TECH[*]}]=$OPTARG;;
           u)   URL=$OPTARG;;
           1)   SAML1=1;;
           2)   SAML2=1;;
           A)   ARTIFACT=1;;
           D)   DS=1;;
           L)   LOGOUT=1;;
           N)   NAMEIDMGMT=1;;
           O)   DECLS=0;;
           \?)  echo metagen [-12ADLNO] -c cert1 [-c cert2 ...] -h host1 [-h host2 ...] [-e entityID]
                exit 1;;
         esac
     done

if [ ${#HOSTS[*]} -eq 0 -a ${#NAKEDHOSTS[*]} -eq 0 ] ; then
    echo metagen [-12ADLN] -c cert1 [-c cert2 ...] -h host1 [-h host2 ...] [-e entityID]
    exit 1
fi

if [ ${#CERTS[*]} -eq 0 ] ; then
    CERTS[${#CERTS[*]}]=sp-cert.pem
fi

for c in ${CERTS[@]}
do
    if  [ ! -s $c ] ; then
        echo Certificate file $c does not exist! 
        exit 2
    fi
done

if [ -z $ENTITYID ] ; then
    if [ ${#HOSTS[*]} -eq 0 ] ; then
        ENTITYID=https://${NAKEDHOSTS[0]}/shibboleth
    else
        ENTITYID=https://${HOSTS[0]}/shibboleth
    fi
fi

if [ ! -z $HOSTLIST ] ; then
    if [ -s $HOSTLIST ] ; then
        while read h
        do
            HOSTS[${#HOSTS[@]}]=$h
        done <$HOSTLIST
    else
        echo File with list of hostnames $l does not exist! 
        exit 2
    fi
fi

# Establish protocols and bindings.

if [ $SAML1 -eq 0 -a $SAML2 -eq 0 ] ; then
    SAML1=1
    SAML2=1
fi

if [ $LOGOUT -eq 1 -o $NAMEIDMGMT -eq 1 ] ; then
    SAML2=1
    SLO[${#SLO[*]}]=$SAML20REDIRECT
    SLO[${#SLO[*]}]=$SAML20POST
    SLOLOC[${#SLOLOC[*]}]="Redirect"
    SLOLOC[${#SLOLOC[*]}]="POST"
fi

if [ $SAML1 -eq 1 -a $SAML2 -eq 1 ] ; then
    PROTENUM="$SAML20PROT $SAML11PROT"
elif [ $SAML1 -eq 1 ] ; then
    PROTENUM="$SAML11PROT"
else
    PROTENUM="$SAML20PROT"
fi

if [ $SAML2 -eq 1 ] ; then
    ACS[${#ACS[*]}]=$SAML20POST
    ACSLOC[${#ACSLOC[*]}]="SAML2/POST"
    ACSLOC[${#ACSLOC[*]}]="SAML2/ECP"
fi

if [ $SAML1 -eq 1 ] ; then
    ACS[${#ACS[*]}]=$SAML1POST
    ACSLOC[${#ACSLOC[*]}]="SAML/POST"
    if [ $ARTIFACT -eq 1 ] ; then
        ACS[${#ACS[*]}]=$SAML1ART
        ACSLOC[${#ACSLOC[*]}]="SAML/Artifact"
    fi
fi

if [ $DECLS -eq 1 ] ; then
    DECLS="xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" "
    if [ $DS -eq 1 ] ; then
        DECLS="${DECLS}xmlns:disco=\"urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol\" "
    fi
else
    DECLS=""
fi

cat <<EOF
<md:EntityDescriptor ${DECLS}entityID="${ENTITYID}">
  <md:SPSSODescriptor protocolSupportEnumeration="${PROTENUM}">
EOF

# Discovery BEGIN
if [ $DS -eq 1 ] ; then

cat << EOF
    <md:Extensions>
EOF

count=1
for h in ${HOSTS[@]}
do
  cat << EOF
      <disco:DiscoveryResponse Binding="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol" Location="https://$h/Shibboleth.sso/DS" index="$count"/>
EOF
  let "count++"
done

for h in ${NAKEDHOSTS[@]}
do
  cat << EOF
      <disco:DiscoveryResponse Binding="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol" Location="http://$h/Shibboleth.sso/DS" index="$count"/>
EOF
  let "count++"
done

cat << EOF
    </md:Extensions>
EOF

fi
# Discovery END

for c in ${CERTS[@]}
do
cat << EOF
    <md:KeyDescriptor>
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>
EOF
grep -v ^- $c
cat << EOF
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>
EOF
done

for f in ${FORMATS[@]}
do
cat << EOF
    <md:NameIDFormat>$f</md:NameIDFormat>
EOF
done

# Logout BEGIN
if [ $LOGOUT -eq 1 ] ; then

for h in ${HOSTS[@]}
do
  count=0
  while [ $count -lt ${#SLO[*]} ]
  do
    cat <<EOF
    <md:SingleLogoutService Binding="${SLO[$count]}" Location="https://$h/Shibboleth.sso/SLO/${SLOLOC[$count]}"/>
EOF
    let "count++"
  done
done

for h in ${NAKEDHOSTS[@]}
do
  count=0
  while [ $count -lt ${#SLO[*]} ]
  do
    cat <<EOF
    <md:SingleLogoutService Binding="${SLO[$count]}" Location="http://$h/Shibboleth.sso/SLO/${SLOLOC[$count]}"/>
EOF
    let "count++"
  done
done

fi
# Logout END

# NameID Mgmt BEGIN
if [ $NAMEIDMGMT -eq 1 ] ; then

for h in ${HOSTS[@]}
do
  count=0
  while [ $count -lt ${#SLO[*]} ]
  do
    cat <<EOF
    <md:ManageNameIDService Binding="${SLO[$count]}" Location="https://$h/Shibboleth.sso/NIM/${SLOLOC[$count]}"/>
EOF
    let "count++"
  done
done

for h in ${NAKEDHOSTS[@]}
do
  count=0
  while [ $count -lt ${#SLO[*]} ]
  do
    cat <<EOF
    <md:ManageNameIDService Binding="${SLO[$count]}" Location="http://$h/Shibboleth.sso/NIM/${SLOLOC[$count]}"/>
EOF
    let "count++"
  done
done

fi
# NameID Mgmt END

index=0
for h in ${HOSTS[@]}
do
  count=0
  while [ $count -lt ${#ACS[*]} ]
  do
    cat <<EOF
    <md:AssertionConsumerService Binding="${ACS[$count]}" Location="https://$h/Shibboleth.sso/${ACSLOC[$count]}" index="$((index+1))"/>
EOF
    let "count++"
    let "index++"
  done
done

for h in ${NAKEDHOSTS[@]}
do
  count=0
  while [ $count -lt ${#ACS[*]} ]
  do
    cat <<EOF
    <md:AssertionConsumerService Binding="${ACS[$count]}" Location="http://$h/Shibboleth.sso/${ACSLOC[$count]}" index="$((index+1))"/>
EOF
    let "count++"
    let "index++"
  done
done

cat <<EOF 
  </md:SPSSODescriptor>
EOF

if [ -n "$ORGNAME" ] ; then
  if [ -z "$URL" ] ; then
    URL=$ENTITYID
  fi
  cat <<EOF
  <md:Organization>
    <md:OrganizationName xml:lang="it">$ORGNAME</md:OrganizationName>
    <md:OrganizationDisplayName xml:lang="it">$ORGNAME</md:OrganizationDisplayName>
    <md:OrganizationURL xml:lang="it">$URL</md:OrganizationURL>
  </md:Organization>
EOF
fi

count=${#ADMIN[*]}
for (( i=0; i<count; i++ ))
do
  IFS="/"; declare -a c=(${ADMIN[$i]})
  cat <<EOF
  <md:ContactPerson contactType="administrative">
    <md:GivenName>${c[0]}</md:GivenName>
    <md:SurName>${c[1]}</md:SurName>
    <md:EmailAddress>${c[2]}</md:EmailAddress>
  </md:ContactPerson>
EOF
done

count=${#SUP[*]}
for (( i=0; i<count; i++ ))
do
  IFS="/"; declare -a c=(${SUP[$i]})
  cat <<EOF
  <md:ContactPerson contactType="support">
    <md:GivenName>${c[0]}</md:GivenName>
    <md:SurName>${c[1]}</md:SurName>
    <md:EmailAddress>${c[2]}</md:EmailAddress>
  </md:ContactPerson>
EOF
done

count=${#TECH[*]}
for (( i=0; i<count; i++ ))
do
  IFS="/"; declare -a c=(${TECH[$i]})
  cat <<EOF
  <md:ContactPerson contactType="technical">
    <md:GivenName>${c[0]}</md:GivenName>
    <md:SurName>${c[1]}</md:SurName>
    <md:EmailAddress>${c[2]}</md:EmailAddress>
  </md:ContactPerson>
EOF
done

cat <<EOF 
</md:EntityDescriptor>

EOF
