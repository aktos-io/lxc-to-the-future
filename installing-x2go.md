# Installing x2go

x2go is an efficient remote desktop software, suitable for slow connections. Besides the [original instructions](https://wiki.x2go.org/doku.php/doc:installation:start) here is the short howto for Debian systems:

## Server 

1. Add the repository archive keys: 

```
sudo apt-key adv --recv-keys --keyserver keys.gnupg.net E1F958385BFE2B6E
```

2. Add the following to `/etc/apt/sources.list.d/x2go.list`: 

```
# X2Go Repository (release builds)
deb http://packages.x2go.org/debian stretch extras main
# X2Go Repository (sources of release builds)
deb-src http://packages.x2go.org/debian stretch extras main

# X2Go Repository (Saimaa ESR builds)
#deb http://packages.x2go.org/debian stretch extras saimaa
# X2Go Repository (sources of Saimaa ESR builds)
#deb-src http://packages.x2go.org/debian stretch extras saimaa

# X2Go Repository (nightly builds)
#deb http://packages.x2go.org/debian stretch extras heuler
# X2Go Repository (sources of nightly builds)
#deb-src http://packages.x2go.org/debian stretch extras heuler
```

3. Install x2go server: 

```console
sudo apt-get update 
sudo apt-get install x2goserver x2goserver-xsession
```

## Client 

```
sudo apt-get install x2goclient
```
