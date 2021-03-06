#!/bin/bash

#========TO-DO
#-Improve echo messages with colors
#-Fill all actions with messages
#-Make control structures to know if last actions fails
#-Test version of zimbra and execute with or without zimbra user zmcertmgr
#========

#Source directory
CERTPATH='/etc/letsencrypt/live'
DIRCERT='mail.yourdomain.com'
SOURCEDIR="$CERTPATH/$DIRCERT"

#Destinatio directory
TEMPDIR="/tmp"
#Temporary working directory
TEMPDESTDIR="$TEMPDIR/$DIRCERT"

CAR="-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----"

#TO-DO Would be great to check the whole certificate but grep with multine
#is a f***ng nightmare.

STROOT="MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/"


#Stop zimbra
#su - zimbra -c "zmcontrol stop"


##Copy the files of the cert to work on temp directory
if [ ! -d "$TEMPDESTDIR" ]; then
	cp -vLr $SOURCEDIR $TEMPDIR
else
	echo -e "==> Borrando directorio...\n"
	rm -fr "$TEMPDESTDIR"
	echo -e "==> Copiando nueva version..."
	cp -vLr $SOURCEDIR $TEMPDIR
	echo -e "\n"
fi
#

#Test if exist in file, if not, add CA to chain
if grep -x "$STROOT" $TEMPDESTDIR/chain.pem  ;
then
   #echo $TEMPDESTDIR/fullchain.pem
   echo -e "==> Existe el CA en chain.pem\n"
   :
else 
   echo -e "==> No existe, insertando CA en fullchain.pem ...\n"
   echo "${CAR}" >> "$TEMPDESTDIR/chain.pem"
fi

#Change the perm
if [ -d "$TEMPDESTDIR" ]; then
	echo -e "==> Changing directory perms to zimbra user/groups...\n"
	chown -R zimbra:zimbra "$TEMPDESTDIR"
else
	echo -e "==> There's no directory\n"
fi

#Verifying as zimbra user all certs (optional)

su - zimbra -c "/opt/zimbra/bin/zmcertmgr verifycrt comm $TEMPDESTDIR/privkey.pem $TEMPDESTDIR/cert.pem $TEMPDESTDIR/chain.pem"

#Copy the privkey.pem as commercial.key

su - zimbra -c "cp $TEMPDESTDIR/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key"


#Deploying the cert

su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm $TEMPDESTDIR/cert.pem $TEMPDESTDIR/chain.pem"


#Final deploy

su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm $TEMPDESTDIR/cert.pem $TEMPDESTDIR/chain.pem"


#Start zimbra
#su - zimbra -c "zmcontrol restart"

